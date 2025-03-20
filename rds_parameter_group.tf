resource "aws_db_parameter_group" "db_params" {
  name   = "postgresql-params"
  family = "postgres17" # Change based on PostgreSQL version

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }
}