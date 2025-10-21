## ClamAV for PUI

resource "aws_route53_record" "clamav" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}-clamav.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_clamav.private_ip]
}