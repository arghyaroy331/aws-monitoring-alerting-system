variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-monitoring-alerting-system"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "admin_ip" {
  description = "Your public IPv4 address with CIDR suffix"
  type        = string
}