resource "aws_db_instance" "postgres_db" {
  identifier             = var.db_identifier
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  username               = var.db_username
  password               = random_password.db_password.result
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group_new.name
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.db_params.name
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_key.arn
  skip_final_snapshot    = true
}

