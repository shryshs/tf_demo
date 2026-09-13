variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Exactly 2 CIDRs, one per subnet/AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "project_name" {
  type    = string
  default = "web-bluegreen"
}

variable "blue_ami_id" {
  description = "Ubuntu AMI ID for blue/alpha — you supply this manually"
  type        = string
}

variable "blue_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "blue_version_tag" {
  type    = string
  default = "alpha-v1.0"
}

variable "enable_green" {
  description = "Part 1: false. Part 2: set true to stand up the green/beta fleet."
  type        = bool
  default     = false
}

variable "green_ami_id" {
  description = "Ubuntu AMI ID for green/beta — you supply this manually"
  type        = string
  default     = ""
}

variable "green_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "green_version_tag" {
  type    = string
  default = "beta-v2.0"
}

variable "blue_weight" {
  type    = number
  default = 100
}

variable "green_weight" {
  type    = number
  default = 0
}

variable "common_tags" {
  type = map(string)
  default = {
    Project = "web-bluegreen"
  }
}
