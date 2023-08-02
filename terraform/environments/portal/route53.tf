###############################################################################################################
############################              OAM Route 53 records                  ###############################
###############################################################################################################

### http://portal-oam-internal.aws.prd.legalservices.gov.uk:80 → Now points to Internal ALB to OHS
### https://portal-oam-console.aws.prd.legalservices.gov.uk:443
### portal-oam-admin.aws.prd.legalservices.gov.uk
### portal-oam1-ms.aws.prd.legalservices.gov.uk
### portal-oam2-ms.aws.prd.legalservices.gov.uk


resource "aws_route53_record" "oam_internal" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-internal.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oam_console" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-console.${data.aws_route53_zone.portal-dev-private.name}"
  type     = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "oam_admin" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam-admin.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oam2-ms.aws.dev.legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam1_nonprod" {
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam1-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oam1-ms.aws.dev.legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_1.private_ip]
}

resource "aws_route53_record" "oam2_prod" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.portal-dev-private.zone_id
  name     = "${local.application_name}-oam2-ms.${data.aws_route53_zone.portal-dev-private.name}" # Correspond to portal-oam2-ms.aws.dev.legalservices.gov.uk
  type     = "A"
  ttl      = 60
  records  = [aws_instance.oam_instance_2[0].private_ip]
}

