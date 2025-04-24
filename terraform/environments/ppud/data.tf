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

# ACM certificate for PPUD UAT ALB
data "aws_acm_certificate" "PPUD_UAT_ALB" {
  count    = local.is-preproduction == true ? 1 : 0
  domain   = "uat.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for WAM UAT ALB
data "aws_acm_certificate" "WAM_UAT_ALB" {
  count    = local.is-preproduction == true ? 1 : 0
  domain   = "wamuat.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for PPUD Training ALB
data "aws_acm_certificate" "PPUD_Training_ALB" {
  count    = local.is-preproduction == true ? 1 : 0
  domain   = "training.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}


# ACM certificate for PPUD PROD ALB
data "aws_acm_certificate" "PPUD_PROD_ALB" {
  count    = local.is-production == true ? 1 : 0
  domain   = "www.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for WAM PROD ALB
data "aws_acm_certificate" "WAM_PROD_ALB" {
  count    = local.is-production == true ? 1 : 0
  domain   = "wam.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}
