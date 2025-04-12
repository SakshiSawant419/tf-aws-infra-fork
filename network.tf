# Use Terraform-managed subnets and VPC

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
}

# Fetch available availability zones

data "aws_availability_zones" "available" {}

# Subnets for EC2 and RDS
locals {
  selected_private_subnets = aws_subnet.private[*].id
  selected_public_subnets  = aws_subnet.public[*].id
}

resource "aws_db_subnet_group" "rds_subnet_group_new" {
  name       = "rds-subnet-group-alt"
  subnet_ids = local.selected_private_subnets

  tags = {
    Name = "rds-subnet-group_new"
  }
}

