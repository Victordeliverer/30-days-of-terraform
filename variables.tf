variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "server_port" {
  description = "Port Apache will listen on and target group will use"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "Port ALB listens on (public access)"
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID (us-east-1)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}