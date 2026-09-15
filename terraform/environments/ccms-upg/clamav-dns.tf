# DNS record for shared ClamAV Server

resource "aws_route53_record" "clamav" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-clamav-${local.env_label}"
  type     = "A"
  ttl      = 300
  records  = [module.clamav.private_ip]
}
