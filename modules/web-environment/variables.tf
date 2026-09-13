variable "environment_name" {
  description = "Short name for this color, e.g. alpha or beta"
  type        = string
}

variable "version_tag" {
  description = "Shown on the web page, e.g. alpha-v1.0 or beta-v2.0"
  type        = string
}

variable "vpc_id" {
  description = "Which VPC to launch into"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs (2, across 2 AZs) the instances launch into"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ALB's security group ID — instances only accept traffic from this SG"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for this environment — you supply this yourself, per region"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "common_tags" {
  description = "Tags every resource in this module gets, merged with Environment/ManagedBy"
  type        = map(string)
  default     = {}
}
