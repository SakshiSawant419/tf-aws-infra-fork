resource "aws_launch_template" "webapp_lt" {
  name_prefix   = "webapp-lt-"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name

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

# Create the .env file for the webapp
cat <<EOT > /opt/csye6225/webapp/.env
DB_HOST=${aws_db_instance.postgres_db.address}
DB_USER=${var.db_username}
DB_PASSWORD=${var.db_password}
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

# Restart systemd service
systemctl daemon-reexec
systemctl restart csye6225.service

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \\
  -a fetch-config \\
  -m ec2 \\
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \\
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