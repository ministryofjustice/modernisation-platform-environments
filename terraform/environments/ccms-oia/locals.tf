#######################################
# Locals
#######################################

locals {
  logging_bucket_name = "${local.application_name}-${local.environment}-logging"
  opa_app_name        = "ccms-opa"
  connector_app_name  = "ccms-connector"
  adaptor_app_name    = "ccms-service-adaptor"


  # Subnet CIDR blocks
  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]

  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  lambda_source_hashes = [
    for f in fileset("./lambda/cloudwatch_alarm_slack_integration", "**") :
    sha256(file("${path.module}/lambda/cloudwatch_alarm_slack_integration/${f}"))
  ]

  lambda_folder_name = ["lambda_delivery", "cloudwatch_sns_layer"]



  # Certificate configuration based on environment
  nonprod_domain = format("%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
  prod_domain    = "laa.service.justice.gov.uk"

  # Primary domain name based on environment
  primary_domain = local.is-production ? local.prod_domain : local.nonprod_domain

  # Subject Alternative Names based on environment
  nonprod_sans = [
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.opa_app_name, var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.connector_app_name, var.networking[0].business-unit, local.environment),
    format("%s.%s-%s.modernisation-platform.service.justice.gov.uk", local.adaptor_app_name, var.networking[0].business-unit, local.environment)
  ]

  prod_sans = [
    format("%s.%s", local.opa_app_name, local.prod_domain),
    format("%s.%s", local.connector_app_name, local.prod_domain),
    format("%s.%s", local.adaptor_app_name, local.prod_domain)
  ]

  subject_alternative_names = local.is-production ? local.prod_sans : local.nonprod_sans

  # Domain validation options mapping (following the example pattern)
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  # Split domain validation by domain type
  modernisation_platform_validations = [for k, v in local.domain_types : v if strcontains(k, "modernisation-platform.service.justice.gov.uk")]
  laa_validations                    = [for k, v in local.domain_types : v if strcontains(k, "laa.service.justice.gov.uk")]
}
