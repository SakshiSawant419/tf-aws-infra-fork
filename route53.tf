data "aws_route53_zone" "dev" {
  name         = var.subdomain
  private_zone = false
}

resource "aws_route53_record" "webapp_dns" {
  zone_id = data.aws_route53_zone.dev.zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}