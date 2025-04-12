# -------------------------
# Load Balancer and Target Group
# -------------------------
resource "aws_lb" "app_lb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = local.selected_public_subnets

  tags = {
    Name = "webapp-alb"
  }
}

resource "aws_lb_target_group" "webapp_tg" {
  name     = "webapp-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Use only if environment is demo
resource "aws_lb_listener" "https_demo_listener" {
  count             = var.environment == "demo" ? 1 : 0
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn # Use imported cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
}
