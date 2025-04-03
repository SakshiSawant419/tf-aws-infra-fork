resource "aws_security_group" "webapp_sg" {
  name        = "webapp-security-group"
  description = "Allow access to app from ALB and SSH from admin"
  vpc_id      = data.aws_vpc.selected_vpc.id

  # Allow SSH (from anywhere — for demo/testing; restrict in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "db_sg" {
  name        = "rds-security-group-v2"
  description = "Allow DB access from app layer only"
  vpc_id      = data.aws_vpc.selected_vpc.id

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

resource "aws_security_group" "lb_sg" {
  name        = "alb-sg"
  description = "Allow inbound web traffic to ALB"
  vpc_id      = data.aws_vpc.selected_vpc.id

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