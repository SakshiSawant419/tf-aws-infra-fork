# -------------------------
resource "aws_launch_template" "webapp_lt" {
  name_prefix   = "webapp-lt-"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.webapp_s3_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = aws_kms_key.ec2_kms.arn
    }
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.webapp_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

apt-get update -y
apt-get install -y jq awscli

# Fetch DB password from Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id webapp-postgres-db-password-v3)
DB_PASSWORD=$(echo $SECRET_JSON | jq -r .SecretString)

mkdir -p /opt/csye6225/webapp

cat <<EOT > /opt/csye6225/webapp/.env
DB_HOST=${aws_db_instance.postgres_db.address}
DB_USER=${var.db_username}
DB_PASSWORD=$DB_PASSWORD
DB_NAME=${var.db_name}
DB_DIALECT=${var.db_dialect}
DB_PORT=${var.db_port}
AWS_BUCKET_NAME=${aws_s3_bucket.app_bucket.bucket}
AWS_REGION=${var.aws_region}
PORT=${var.app_port}
EOT

chown ubuntu:ubuntu /opt/csye6225/webapp/.env
chmod 600 /opt/csye6225/webapp/.env

systemctl daemon-reexec
systemctl restart csye6225.service

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "webapp-instance"
    }
  }
}