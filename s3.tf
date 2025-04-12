# S3 Bucket for application uploads
resource "aws_s3_bucket" "app_bucket" {
  bucket = "webapp-s3-bucket-${var.aws_region}-${random_string.bucket_suffix.result}"

  tags = {
    Name = "webapp-s3-bucket"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Enable server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket lifecycle policy - fixed with filter
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {
      prefix = "" # Apply to all objects
    }

    expiration {
      days = 90
    }
  }
}