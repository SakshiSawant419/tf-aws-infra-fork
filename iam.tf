resource "aws_iam_role" "ec2_role" {
  name = "EC2RoleForApp2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "EC2S3Access"
  description = "Allow EC2 to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}",
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name = "CloudWatchAgentPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "secretsmanager_access" {
  name        = "SecretsManagerAccess"
  description = "Allow EC2 to get DB password from Secrets Manager and decrypt with KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.email_credentials.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          aws_kms_key.secrets_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secretsmanager_access.arn
}

resource "aws_iam_instance_profile" "webapp_s3_profile" {
  name = "WebAppEC2InstanceProfile-v2"
  role = aws_iam_role.ec2_role.name
}