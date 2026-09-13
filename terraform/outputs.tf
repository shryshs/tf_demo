# outputs.tf

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"

  value = aws_lb.app.dns_name
}

output "alb_url" {
  description = "Application URL"

  value = "http://${aws_lb.app.dns_name}"
}

output "asg_name" {
  description = "Auto Scaling Group name"

  value = aws_autoscaling_group.app.name
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
