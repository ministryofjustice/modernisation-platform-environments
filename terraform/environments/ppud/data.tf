#### This file can be used to store data specific to the member account ####


# ACM certificate for PPUD and WAM ALB
data "aws_acm_certificate" "internaltest_cert" {
  domain   = "internaltest.aws.gov.uk"
  statuses = ["ISSUED"]
}
