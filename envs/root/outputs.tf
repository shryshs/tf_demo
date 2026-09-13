output "alb_dns_name" {
  description = "open this in browser"
  value       = aws_lb.this.dns_name
}

output "blue_asg_name" {
  value = module.blue.asg_name
}

output "green_asg_name" {
  value = var.enable_green ? module.green[0].asg_name : null
}

output "current_weights" {
  value = "blue=${var.blue_weight} green=${var.green_weight}"
}
