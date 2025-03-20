# Security Group for Web Application
resource "aws_security_group" "app_sg" {
  name        = "webapp-security-group"
  description = "Allow inbound traffic for WebApp"
  vpc_id      = aws_vpc.main.id

  # Allow SSH (22), HTTP (80), HTTPS (443), and Application Port (8080)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (consider restricting this)
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
    cidr_blocks = ["0.0.0.0/0"] # Allow public access to your application
  }

  # Allow all outbound traffic
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

# EC2 Instance for Web Application
resource "aws_instance" "webapp_instance" {
  ami           = var.ami_id # Your custom AMI ID
  instance_type = "t2.micro"
  subnet_id     = local.selected_public_subnets[0]

  vpc_security_group_ids      = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.webapp_s3_profile.name # Attach IAM role
  disable_api_termination     = false

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "User Data Execution Started" >> /var/log/user-data.log

    # Ensure the /opt/webapp/ directory exists
    mkdir -p /opt/webapp/
    chmod 777 /opt/webapp/

    # Write database configuration to .env
    cat <<EOT > /opt/webapp/.env
    DB_HOST=${aws_db_instance.postgres_db.endpoint}
    DB_USER=${var.db_username}
    DB_PASSWORD=${var.db_password}
    DB_NAME=${var.db_name}
    DB_DIALECT=${var.db_dialect}
    DB_PORT=${var.db_port}
    AWS_BUCKET_NAME=${aws_s3_bucket.app_bucket.bucket}    
    EOT
   
  
    chmod 600 /opt/webapp/.env

    # Ensure the webapp service exists
    cat <<SERVICE > /etc/systemd/system/webapp.service
    [Unit]
    Description=Web Application
    After=network.target

    [Service]
    ExecStart=/usr/bin/node /opt/webapp/app.js
    Restart=always
    User=ubuntu
    Group=ubuntu
    EnvironmentFile=/opt/webapp/.env

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Reload systemd and start the service
    systemctl daemon-reload
    systemctl enable webapp.service
    systemctl restart webapp.service

    echo "User Data Execution Completed" >> /var/log/user-data.log
  EOF

  tags = {
    Name = "webapp-instance"
  }
}

# Output Public IP
# output "instance_public_ip" {
# #   description = "Public IP of the EC2 instance"
#   value       = aws_instance.webapp_instance.public_ip
# }