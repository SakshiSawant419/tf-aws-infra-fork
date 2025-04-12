

# Security group for the Application Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "alb-sg"
  description = "Allow inbound web traffic to ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Security group for the web application
resource "aws_security_group" "webapp_sg" {
  name        = "webapp-security-group"
  description = "Allow access to app from ALB only and SSH from admin"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from specific admin IPs only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_block]
  }

  # Allow app port (8080) only from Load Balancer SG
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Outbound to all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webapp-sg"
  }
}

# Security group for RDS
resource "aws_security_group" "db_sg" {
  name        = "rds-security-group-v2"
  description = "Allow DB access from app layer only"
  vpc_id      = aws_vpc.main.id

  # Only allow Postgres traffic from WebApp SG
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp_sg.id]
  }

  # Outbound to all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

