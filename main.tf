provider "aws" {
  region = var.region
}

# AZs
data "aws_availability_zones" "all" {}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default subnets (public)
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# -----------------------------
# Security Group - ALB
# -----------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Security Group - Web Servers
# -----------------------------
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"
  description = "Allow traffic only from ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
# -----------------------------
# Launch Template
# -----------------------------
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # IMPORTANT: ensure networking is explicit
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

user_data = base64encode(<<-EOF
  #!/bin/bash
  exec > /var/log/user-data.log 2>&1

  yum update -y
  yum install -y httpd

  # Force Apache to listen on desired port (robust way)
  echo "Listen ${var.server_port}" > /etc/httpd/conf.d/port.conf

  systemctl enable httpd
  systemctl restart httpd

  echo "<h1>Clustered Web Server - Highly Available 🚀</h1>" > /var/www/html/index.html
  EOF
)

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------
# Target Group
# -----------------------------
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = var.server_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200"
  }
}

# -----------------------------
# ALB
# -----------------------------
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# -----------------------------
# Listener
# -----------------------------
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# -----------------------------
# Auto Scaling Group
# -----------------------------
resource "aws_autoscaling_group" "web_asg" {
  name             = "web-asg"
  min_size         = 2
  max_size         = 5
  desired_capacity = 2

  vpc_zone_identifier = data.aws_subnets.default.ids

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "Day5-WebServer"
    propagate_at_launch = true
  }
}

# -----------------------------
# Output
# -----------------------------
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
  description = "The domain name of the load balancer"
}

