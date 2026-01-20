#### This file can be used to store data specific to the member account ####
data "aws_availability_zones" "available" {}

# Data sources to fetch hosted zone information from each environment account
# These fetch the NS records dynamically from the account zones

data "aws_route53_zone" "development_account_zone" {
  count    = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  provider = aws.cloud-platform-non-live-development
  name     = "non-live-development.temp.cloud-platform.service.justice.gov.uk"
}

data "aws_route53_zone" "test_account_zone" {
  count    = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  provider = aws.cloud-platform-non-live-test
  name     = "non-live-test.temp.cloud-platform.service.justice.gov.uk"
}

data "aws_route53_zone" "preproduction_account_zone" {
  count    = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  provider = aws.cloud-platform-non-live-preproduction
  name     = "non-live-preproduction.temp.cloud-platform.service.justice.gov.uk"
}
