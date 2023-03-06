#### This file can be used to store data specific to the member account ####


# Get AWS directory service password from secret manager
data "aws_secretsmanager_secret_version" "creds" {
  # Fill in the name you gave to your secret
  secret_id = "ad-creds"
  filter {
    name   = "tag:name"
    values = ["development"]
  }
}


# ACM certificate for PPUD and WAM ALB
data "aws_acm_certificate" "internaltest_cert" {
  domain   = "internaltest.aws.gov.uk"
  statuses = ["ISSUED"]
}
