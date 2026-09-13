output "target_group_arn" {
  description = "Used by the root module to plug this color into the shared ALB listener"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  value = aws_security_group.ec2.id
}

output "asg_name" {
  value = aws_autoscaling_group.this.name
}
