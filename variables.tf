variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID of the custom image"
  type        = string # Replace with your actual AMI ID
}

variable "app_port" {
  description = "Port on which the web application runs"
  type        = number
}



variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_dialect" {
  description = "Database dialect (e.g., postgres)"
  type        = string
  default     = "postgres"
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "key_name" {
  description = "Name of the EC2 Key Pair to allow SSH access"
  type        = string
}

variable "subdomain" {
  description = "Subdomain to use for Route53 record"
  type        = string
}

variable "db_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = "csye6225-a6"
}

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  description = "Instance class for the RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "admin_cidr_block" {
  description = "CIDR block for admin SSH access"
  type        = string
  default     = "10.0.0.0/24" # Change this to your actual admin IP range
}