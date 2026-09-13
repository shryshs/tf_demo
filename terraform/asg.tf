# asg.tf

resource "aws_autoscaling_group" "app" {
  name = "myapp-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 3

  vpc_zone_identifier = module.vpc.private_subnets

  health_check_type = "ELB"

  health_check_grace_period = 300

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  launch_template {
    id = aws_launch_template.app.id

    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "myapp-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}
