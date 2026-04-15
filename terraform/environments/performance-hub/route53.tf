# Note: The prod and preprod records are managed by operations engineering's DNS repo and have a CNAME to the 
# equivalent .modernisation-platform.service.justice.gov.uk record
# https://github.com/ministryofjustice/dns/blob/a4e0ebfdd7cd5fa8b85299272b53aa6127383ae4/hostedzones/service.justice.gov.uk.yaml#L962
# https://github.com/ministryofjustice/dns/blob/a4e0ebfdd7cd5fa8b85299272b53aa6127383ae4/hostedzones/service.justice.gov.uk.yaml#L1730

/*
1. Create ACM certs using "aws_acm_certificate"

2. This will create a cert with a CNAME value a bit like this: _f0f2cb35920a21c336c8a8d4eadcc9f3.jddtvkljgg.acm-validations.aws.

3. Raise a PR in DNS repo to create this record: https://github.com/ministryofjustice/dns/blob/a4e0ebfdd7cd5fa8b85299272b53aa6127383ae4/hostedzones/service.justice.gov.uk.yaml#L24
    (note DNS records should be alphabetical)

4. Cert validation will automatically proceed once the DNS change is merged and applied

5. Validated certs can be added as cert_arn in application_variables
*/

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  count             = local.is-production ? 0 : 1
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "external_preprod" {
  count = local.is-preproduction ? 1 : 0
  #domain_name       = "hmpps-performance-hub.service.justice.gov.uk"
  domain_name       = "staging.hmpps-performance-hub.service.justice.gov.uk"
  validation_method = "DNS"

  #subject_alternative_names = ["staging.hmpps-performance-hub.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "external_prod" {
  count             = local.is-production ? 1 : 0
  domain_name       = "hmpps-performance-hub.service.justice.gov.uk"
  validation_method = "DNS"

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  count                   = local.is-production ? 0 : 1
  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}