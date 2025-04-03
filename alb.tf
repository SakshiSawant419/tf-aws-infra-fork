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
  vpc_id   = data.aws_vpc.selected_vpc.id

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
}