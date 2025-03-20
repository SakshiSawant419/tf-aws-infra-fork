# 🔹 Fetch the correct VPC dynamically (remove hardcoded VPC ID)
data "aws_vpc" "selected_vpc" {
  id = "vpc-0abff8e686c22038f" # ✅ Your chosen VPC
}

# Fetch all subnets in the selected VPC
data "aws_subnets" "existing_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id] # ✅ Fetch subnets from the correct VPC
  }
}

# Fetch detailed subnet information
data "aws_subnet" "all_subnet_details" {
  for_each = toset(data.aws_subnets.existing_vpc_subnets.ids)
  id       = each.value
}

# Identify private and public subnets within the correct VPC
locals {
  private_subnets = [for s in data.aws_subnet.all_subnet_details : s.id if s.map_public_ip_on_launch == false]
  public_subnets  = [for s in data.aws_subnet.all_subnet_details : s.id if s.map_public_ip_on_launch == true]
}

# Select subnets for EC2 (public) and RDS (private)
locals {
  selected_private_subnets = slice(local.private_subnets, 0, 2) # ✅ For RDS
  selected_public_subnets  = slice(local.public_subnets, 0, 2)  # ✅ For EC2
}

# 🔹 Fetch available availability zones dynamically
data "aws_availability_zones" "available" {}

# 🔹 Create a DB subnet group for RDS using the dynamically selected private subnets
resource "aws_db_subnet_group" "rds_subnet_group_new" {
  name       = "rds-subnet-group_new"
  subnet_ids = local.selected_private_subnets # ✅ Ensure subnets belong to vpc-0abff8e686c22038f

  tags = {
    Name = "rds-subnet-group_new"
  }
}

