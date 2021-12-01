data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

resource "aws_route53_record" "database" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "database.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.db_server.private_ip]
}