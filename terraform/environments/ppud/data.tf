#### This file can be used to store data specific to the member account ####


# ACM certificate for PPUD TEST ALB
data "aws_acm_certificate" "PPUD_internaltest_cert" {
  count    = local.is-development == true ? 1 : 0
  domain   = "internaltest.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for WAM TEST ALB
data "aws_acm_certificate" "WAM_internaltest_cert" {
  count    = local.is-development == true ? 1 : 0
  domain   = "waminternaltest.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for PPUD / WAM ALB for UAT and PROD
data "aws_acm_certificate" "internaltest_cert" {
  count    = local.is-development == false ? 1 : 0
  domain   = "internaltest.aws.gov.uk"
  statuses = ["ISSUED"]
}
