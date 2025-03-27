resource "aws_security_group" "webapp_backend_sg" {
  name        = "webapp-security-group"
  description = "Allow inbound traffic for WebApp"
  vpc_id      = data.aws_vpc.selected_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
}

resource "aws_instance" "webapp_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = local.selected_public_subnets[0]

  vpc_security_group_ids      = [aws_security_group.webapp_backend_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.webapp_s3_profile.name
  disable_api_termination     = false

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "User Data Execution Started" >> /var/log/user-data.log

    # Ensure application directory exists
    mkdir -p /opt/webapp/
    chmod 750 /opt/webapp/

    # Write environment variables to .env file
    cat <<EOT > /opt/webapp/.env
    DB_HOST=${aws_db_instance.postgres_db.address}
    DB_USER=${var.db_username}
    DB_PASSWORD=${var.db_password}
    DB_NAME=${var.db_name}
    DB_DIALECT=${var.db_dialect}
    DB_PORT=${var.db_port}
    AWS_BUCKET_NAME=${aws_s3_bucket.app_bucket.bucket}
    PORT=8080
    EOT

    # Secure the .env file
    chmod 640 /opt/webapp/.env
    chown csye6225:csye6225 /opt/webapp/.env

    # Register Node.js app as a systemd service
    cat <<SERVICE > /etc/systemd/system/webapp.service
    [Unit]
    Description=Web Application
    After=network.target

    [Service]
    ExecStart=/usr/bin/node /opt/webapp/app.js
    Restart=always
    User=csye6225
    Group=csye6225
    EnvironmentFile=/opt/webapp/.env

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Start the webapp service
    systemctl daemon-reload
    systemctl enable webapp.service
    systemctl restart webapp.service

    # Start CloudWatch Agent using pre-baked config
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \\
      -a fetch-config \\
      -m ec2 \\
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \\
      -s

    echo "User Data Execution Completed" >> /var/log/user-data.log
  EOF

  tags = {
    Name = "webapp-instance"
  }
}