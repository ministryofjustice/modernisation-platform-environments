#### This file can be used to store data specific to the member account ####


# ACM certificate for PPUD TEST ALB
data "aws_acm_certificate" "PPUD_internaltest_cert" {
  domain   = "internaltest.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}

# ACM certificate for WAM TEST ALB
data "aws_acm_certificate" "WAM_internaltest_cert" {
  domain   = "waminternaltest.ppud.justice.gov.uk"
  statuses = ["ISSUED"]
}