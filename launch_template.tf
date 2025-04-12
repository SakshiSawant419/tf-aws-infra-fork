resource "aws_launch_template" "webapp_lt" {
  name_prefix   = "webapp-lt-"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  # Apply KMS encryption to EBS volumes
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.webapp_s3_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.webapp_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash

echo "User Data Execution Started" >> /var/log/user-data.log

# Install tools
apt-get update -y
apt-get install -y jq awscli

# Get Database Password from Secrets Manager
DB_PASSWORD_JSON=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_password.name} --region ${var.aws_region} --query SecretString --output text)
DB_PASSWORD=$(echo $DB_PASSWORD_JSON | jq -r '.password')

# Add error handling and logging
if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: Failed to retrieve database password from Secrets Manager" >> /var/log/user-data.log
else
  echo "Successfully retrieved database password" >> /var/log/user-data.log
fi

# Create .env file
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

# Set permissions
chown csye6225:csye6225 /opt/csye6225/webapp/.env
chmod 600 /opt/csye6225/webapp/.env

# Restart app
systemctl daemon-reexec
systemctl restart csye6225.service

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "User Data Execution Completed" >> /var/log/user-data.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "webapp-instance"
    }
  }
}