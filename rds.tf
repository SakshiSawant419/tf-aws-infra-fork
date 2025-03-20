resource "aws_db_instance" "postgres_db" {
  identifier             = "csye6225"
  engine                 = "postgres"
  engine_version         = "17"
  instance_class         = "db.t3.micro" # Cheapest instance
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group_new.name
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.db_params.name
  skip_final_snapshot    = true
}
