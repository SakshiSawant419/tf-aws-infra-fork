# -------------------------
# KMS Keys for Resources
# -------------------------
resource "aws_kms_key" "ec2_kms" {
  description             = "KMS key for EC2 encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_key" "rds_kms" {
  description             = "KMS key for RDS encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_key" "s3_kms" {
  description             = "KMS key for S3 encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_key" "secrets_kms" {
  description             = "KMS key for Secrets Manager encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

# -------------------------
# Secret Manager for DB Password
# -------------------------
resource "random_password" "db_pass" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?.,"  # Fixed: Removed '/' and '"'
}

resource "aws_secretsmanager_secret" "db_password_secret" {
  name                    = "webapp-postgres-db-password-v3"
  kms_key_id              = aws_kms_key.secrets_kms.arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_password_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.db_pass.result
}  # ✅ Only secrets and password logic remain here
