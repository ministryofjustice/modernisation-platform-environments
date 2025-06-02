#### This file can be used to store locals specific to the member account ####

locals {
  env_account_id     = local.environment_management.account_ids[terraform.workspace]
  env_account_region = data.aws_region.current.id

  # For CloudFront validation for MAAT

  cloudfront_domain_types = { for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  cloudfront_domain_name_main   = [for k, v in local.cloudfront_domain_types : v.name if k == local.cloudfront_domain]
  cloudfront_domain_name_sub    = [for k, v in local.cloudfront_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_record_main = [for k, v in local.cloudfront_domain_types : v.record if k == local.cloudfront_domain]
  cloudfront_domain_record_sub  = [for k, v in local.cloudfront_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_type_main   = [for k, v in local.cloudfront_domain_types : v.type if k == local.cloudfront_domain]
  cloudfront_domain_type_sub    = [for k, v in local.cloudfront_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  # For LBs validation for MAAT
  lbs_prod_domain = local.environment == "production" ? "means-assessment-administration.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"

  lbs_domain_types = { for dvo in aws_acm_certificate.load_balancers.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  lbs_domain_name_main   = [for k, v in local.lbs_domain_types : v.name if k == local.cloudfront_domain]
  lbs_domain_name_sub    = [for k, v in local.lbs_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_record_main = [for k, v in local.lbs_domain_types : v.record if k == local.cloudfront_domain]
  lbs_domain_record_sub  = [for k, v in local.lbs_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  lbs_domain_type_main   = [for k, v in local.lbs_domain_types : v.type if k == local.cloudfront_domain]
  lbs_domain_type_sub    = [for k, v in local.lbs_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  xdr_tags = join(", ", [upper(local.application_name), upper(local.environment), upper(var.networking[0].business-unit)])
}