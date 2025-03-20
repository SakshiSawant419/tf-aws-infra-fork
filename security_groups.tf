resource "aws_security_group" "webapp_sg" {
  name        = "app-security-group"
  description = "Allow inbound traffic for WebApp"
  vpc_id      = data.aws_vpc.selected_vpc.id  # ✅ Ensures it is in the correct VPC

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow public access to web app
  }

  tags = {
    Name = "app-security-group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS database"
  vpc_id      = data.aws_vpc.selected_vpc.id  # ✅ Ensures this SG is in the correct VPC

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.webapp_sg.id]  # ✅ Allows database access only from the web app
  }

  tags = {
    Name = "rds-security-group"
  }
}

