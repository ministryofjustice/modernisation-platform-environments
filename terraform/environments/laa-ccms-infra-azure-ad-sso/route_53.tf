### LOADBALANCER
resource "aws_route53_record" "sg_ebs_vision_db_a_record" {
  provider   = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}.${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebs_vision_db_lb.dns_name
    zone_id                = aws_lb.ebs_vision_db_lb.zone_id
    evaluate_target_health = true

  }
}


resource "aws_route53_record" "ebs_vision_db_lb_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebs_vision_db_lb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.sg_ebs_vision_db_a_record.fqdn]
}

# networking[0].application = laa-ccms-infra-azure-ad-sso
# networking[0].business-unit = laa
# Workspace: laa-ccms-infra-azure-ad-sso-development
# trimprefix(terraform.workspace, "${var.networking[0].application}-")
# local.environment = trim-prefix(laa-ccms-infra-azure-ad-sso-development, laa-ccms-infra-azure-ad-sso) = development
# ${local.dns_name} =modernisation-platform.service.justice.gov.uk

# laa-ccms-infra-azure-ad-sso.laa.development.modernisation-platform.service.justice.gov.uk

#
#

#
# fqdn - laa-ccms-infra-azure-ad-sso.laa.development.modernisation-platform.service.justice.gov.uk.laa-development.modernisation-platform.service.justice.gov.uk
#
#
