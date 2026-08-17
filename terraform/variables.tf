variable "project_name" {
  description = "Base name used for AWS resource naming"
  type        = string
  default     = "nm-hav-a-seat"
}

variable "aws_region" {
  description = "AWS region where the Hav-A-Seat infrastructure will be deployed"
  type        = string
  default     = "af-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the Hav-A-Seat VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the infrastructure"
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_password" {
  description = "Password for the Hav-A-Seat PostgreSQL database"
  type        = string
  sensitive   = true
}