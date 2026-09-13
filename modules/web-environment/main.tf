locals {
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment_name
      ManagedBy   = "terraform"
    }
  )
}

resource "aws_security_group" "ec2" {
  name_prefix = "${var.environment_name}-ec2-"
  description = "Allow HTTP only from the ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound (updates, package installs, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.environment_name}-ec2-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.environment_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.tags, { Name = "${var.environment_name}-tg" })
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.environment_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    version_tag      = var.version_tag
    environment_name = var.environment_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.environment_name}-instance" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.environment_name}-asg-"
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  target_group_arns         = [aws_lb_target_group.this.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(local.tags, { Name = "${var.environment_name}-instance" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
