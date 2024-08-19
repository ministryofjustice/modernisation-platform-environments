locals {
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  certificate_arn = aws_acm_certificate.external.arn

  error_codes = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14,
    16, 17, 18, 19, 20, 21, 33, 34, 35, 36, 48, 49,
    50, 51, 52, 53, 54, 60, 61, 64, 65, 66, 67, 68,
    69, 70, 71, 76, 80, 81, 82, 83, 84, 85, 86, 87,
    88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 100, 101,
    112, 113, 114, 118, 119, 120, 121, 122, 123, 4096,
    16654
  ]
  formatted_error_codes = [for error_code in local.error_codes : "err=${error_code}\s"]
}
