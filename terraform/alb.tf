# alb.tf

resource "aws_lb_target_group" "app" {
  name = "myapp-target-group"

  port     = 80
  protocol = "HTTP"

  vpc_id = module.vpc.vpc_id

  target_type = "instance"

  health_check {
    enabled = true

    protocol = "HTTP"
    port     = "traffic-port"
    path     = "/"

    healthy_threshold   = 2
    unhealthy_threshold = 3

    timeout  = 5
    interval = 30

    matcher = "200"
  }

  tags = {
    Name        = "myapp-target-group"
    Environment = "dev"
  }
}

resource "aws_lb" "app" {
  name = "myapp-alb"

  load_balancer_type = "application"

  internal = false

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = module.vpc.public_subnets

  tags = {
    Name        = "myapp-alb"
    Environment = "dev"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }
}
