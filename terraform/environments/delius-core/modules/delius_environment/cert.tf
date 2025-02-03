data "aws_ram_resource_share" "shared_ca" {
  name = var.shared_ca_name
  resource_owner = "OTHER-ACCOUNTS"
}

data "aws_acmpca_certificate_authority" "shared_ca" {
  arn = data.aws_ram_resource_share.shared_ca.resource_arns[0]
}

resource "aws_acm_certificate" "cert" {
  certificate_authority_arn = data.aws_acmpca_certificate_authority.shared_ca.arn
  domain_name = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = ["delius-core-dev-db-1.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk"]

  lifecycle {
    create_before_destroy = true
  }
}
