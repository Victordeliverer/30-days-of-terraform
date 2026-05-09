# 30 Days of Terraform

This repository documents my 30‑day journey learning and practicing Terraform.  
Each day includes hands‑on examples, notes, and real infrastructure deployments.

## Goals
- Build a strong foundation in Infrastructure as Code (IaC)
- Understand Terraform workflows and best practices
- Deploy real AWS resources using Terraform
- Improve automation and cloud engineering skills

## Progress
- **Day 1:** Installing Terraform, setting up AWS provider  
- **Day 2:** Creating first EC2 instance  
- More days coming…

## Tools & Technologies
- Terraform
- AWS (EC2, VPC, IAM, S3, etc.)
- Git & GitHub

## How to Use This Repo
Each folder represents a day.  
You can clone the repo and explore the code:

```sh
git clone git@github.com:Victordeliverer/30-days-of-terraform.git

Webserver Cluster Module
Overview
The webserver-cluster module deploys a highly available web application stack on AWS using Terraform.
This module provisions:

An Application Load Balancer (ALB)

A Target Group with health checks

A Launch Template with EC2 bootstrap configuration

An Auto Scaling Group (ASG)

Security Groups for the ALB and EC2 instances


The module is designed for multi-environment deployments such as:

Development

Staging

Production

It also supports disabling the Auto Scaling Group for low-cost development environments.

Inputs
cluster_name
Name prefix used for all resources created by the module.
Example:
cluster_name = "webservers-dev"

instance_type
EC2 instance type used by the web servers.
Default:
"t2.micro"

ami_id
AMI ID used for the EC2 instances.
Example:
ami_id = "ami-0c02fb55956c7d316"

server_port
Port Apache listens on inside the EC2 instances.
Default:
8080

alb_port
Port the Application Load Balancer listens on.
Default:
80

min_size
Minimum number of EC2 instances in the Auto Scaling Group.
Example:
min_size = 2

max_size
Maximum number of EC2 instances in the Auto Scaling Group.
Example:
max_size = 5

vpc_id
VPC ID where all resources will be deployed.
Example:
vpc_id = data.aws_vpc.default.id

subnet_ids
List of subnet IDs used by the ALB and Auto Scaling Group.
Example:
subnet_ids = data.aws_subnets.default.ids

enable_asg
Controls whether the Auto Scaling Group should be created.
Useful for development environments where you want to avoid EC2 costs.
Default:
true
Example:
enable_asg = false

Outputs
alb_dns_name
Returns the DNS name of the Application Load Balancer.
Example:
output "alb_dns_name" {  value = module.webserver_cluster.alb_dns_name}

asg_name
Returns the name of the Auto Scaling Group when enabled.
Example:
output "asg_name" {  value = module.webserver_cluster.asg_name}

Usage Example
module "webserver_cluster" {  source = "github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.1"  cluster_name  = "webservers-dev"  instance_type = "t2.micro"  min_size    = 0  max_size    = 4  server_port = 8080  ami_id      = "ami-0c02fb55956c7d316"  vpc_id     = data.aws_vpc.default.id  subnet_ids = data.aws_subnets.default.ids  # Disable ASG in development  enable_asg = false}

Architecture
The module creates the following infrastructure flow:
Internet   ↓Application Load Balancer (ALB)   ↓Target Group   ↓Auto Scaling Group (ASG)   ↓EC2 Web Servers

Known Limitations / Gotchas


1. File Path Resolution (path.module)
Terraform resolves file paths relative to the root module.
When loading user-data templates inside modules, always use:
templatefile("${path.module}/user-data.sh", {...})
Do NOT use:
./user-data.sh
Using relative paths incorrectly can cause Terraform to fail when the module is called from another directory.


2. ASG Can Be Disabled in Development
To avoid unnecessary AWS charges during development:
enable_asg = false
This prevents the creation of:

Auto Scaling Groups

EC2 instances

while still allowing the ALB and supporting infrastructure to exist.


3. ALB Listener Dependency
The Auto Scaling Group depends on the ALB listener to avoid race conditions during deployment.
This dependency is handled using:
depends_on = [aws_lb_listener.web_listener]
Without this dependency, instances may launch before the listener is ready, causing target registration or health check failures.


Best Practices Implemented

Reusable Terraform module structure
Multi-environment support
Input variables for flexibility
Outputs for integration with other modules
Health checks for availability
Secure security group configuration
High availability using an ALB + ASG
Cost optimization support for dev environments
