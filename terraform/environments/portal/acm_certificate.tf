resource "aws_acm_certificate" "dev_legalservices_cert" {
  domain_name = "${local.application_data.accounts[local.environment].acm_domain_name}"
  subject_alternative_names = ["${local.application_data.accounts[local.environment].acm_alt_domain_name}"]
  validation_method = "DNS"
   
   
   tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}" }
  )

  lifecycle {
    create_before_destroy = true
  }
}