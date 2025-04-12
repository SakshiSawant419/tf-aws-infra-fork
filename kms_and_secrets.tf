# KMS Keys with 90-day rotation period
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = {
    Name = "ec2-encryption-key"
  }
}

resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = {
    Name = "rds-encryption-key"
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = {
    Name = "s3-encryption-key"
  }
}

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = {
    Name = "secrets-encryption-key"
  }
}

# KMS Aliases for easier reference
resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# Random password generation for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store DB password in Secrets Manager with custom name to avoid conflict
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "rds-db-password-${var.aws_region}"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0 # To avoid conflicts with deletion

  tags = {
    Name = "Database Password Secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.db_password.result,
    engine   = var.db_engine,
    host     = aws_db_instance.postgres_db.address,
    port     = var.db_port,
    dbname   = var.db_name
  })
}

# Add email service credentials to Secrets Manager
resource "aws_secretsmanager_secret" "email_credentials" {
  name                    = "email-service-credentials-${var.aws_region}"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0

  tags = {
    Name = "Email Service Credentials"
  }
}

# You can populate this with your email service credentials
resource "aws_secretsmanager_secret_version" "email_credentials_version" {
  secret_id = aws_secretsmanager_secret.email_credentials.id
  secret_string = jsonencode({
    smtp_host     = "smtp.example.com",
    smtp_port     = "587",
    smtp_username = "your-smtp-username",
    smtp_password = "your-smtp-password"
  })
}