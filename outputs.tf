output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The DNS name of the ALB"
}

output "asg_name" {
  value       = aws_autoscaling_group.web_asg.name
  description = "The name of the Auto Scaling Group"
}
