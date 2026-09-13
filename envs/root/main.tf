data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-vpc"
    Environment = "shared"
    ManagedBy   = "terraform"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-igw"
    Environment = "shared"
    ManagedBy   = "terraform"
  })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-public-${count.index}"
    Environment = "shared"
    ManagedBy   = "terraform"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-public-rt"
    Environment = "shared"
    ManagedBy   = "terraform"
  })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-alb-sg"
    Environment = "shared"
    ManagedBy   = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-alb"
    Environment = "shared"
    ManagedBy   = "terraform"
  })
}


module "blue" {
  source = "../../modules/web-environment"

  environment_name      = "alpha"
  version_tag           = var.blue_version_tag
  vpc_id                = aws_vpc.this.id
  subnet_ids            = aws_subnet.public[*].id
  alb_security_group_id = aws_security_group.alb.id
  ami_id                = var.blue_ami_id
  instance_type         = var.blue_instance_type
  common_tags           = var.common_tags
}

module "green" {
  count  = var.enable_green ? 1 : 0
  source = "../../modules/web-environment"

  environment_name      = "beta"
  version_tag           = var.green_version_tag
  vpc_id                = aws_vpc.this.id
  subnet_ids            = aws_subnet.public[*].id
  alb_security_group_id = aws_security_group.alb.id
  ami_id                = var.green_ami_id
  instance_type         = var.green_instance_type
  common_tags           = var.common_tags
}


locals {
  weighted_target_groups = concat(
    [
      {
        arn    = module.blue.target_group_arn
        weight = var.blue_weight
      }
    ],
    var.enable_green ? [
      {
        arn    = module.green[0].target_group_arn
        weight = var.green_weight
      }
    ] : []
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = local.weighted_target_groups
        content {
          arn    = target_group.value.arn
          weight = target_group.value.weight
        }
      }
    }
  }
}
