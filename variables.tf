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

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID (us-east-1)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  description = "EC2 instance type per environment"
  type        = string
  default = "t2.micro"
}

variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type = number
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB and ASG"
  type        = list(string)
}

