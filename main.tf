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
  name = "${var.cluster_name}-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = var.vpc_id

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
  name_prefix = "${var.cluster_name}-web-sg-"
  description = "Allow traffic only from ALB"
  vpc_id      = var.vpc_id

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
}
# -----------------------------
# Launch Template
# -----------------------------
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(
    templatefile("${path.module}/user-data.sh", {
      server_port  = var.server_port
      cluster_name = var.cluster_name
    })
  )
}

# -----------------------------
# Target Group
# -----------------------------
resource "aws_lb_target_group" "web_tg" {
  name = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids
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
  name = "${var.cluster_name}-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.min_size

  vpc_zone_identifier = var.subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete = true

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "30days-terraform-WebServer"
    propagate_at_launch = true
  }
}



