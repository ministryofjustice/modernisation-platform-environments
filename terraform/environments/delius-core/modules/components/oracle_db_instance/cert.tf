locals {
  cert_prefix    = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${local.instance_name_index}"
  shared_ca_name = contains(["prod", "preprod", "stage"], var.env_name) ? "acm-pca-live" : "acm-pca-non-live"
}

data "aws_ram_resource_share" "shared_ca" {
  name           = local.shared_ca_name
  resource_owner = "OTHER-ACCOUNTS"
}

data "aws_acmpca_certificate_authority" "shared_ca" {
  arn = data.aws_ram_resource_share.shared_ca.resource_arns[0]
}

resource "aws_acm_certificate" "cert" {
  certificate_authority_arn = data.aws_acmpca_certificate_authority.shared_ca.arn
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = ["${local.cert_prefix}.${var.account_config.dns_suffix}"]

  lifecycle {
    create_before_destroy = true
  }
}

