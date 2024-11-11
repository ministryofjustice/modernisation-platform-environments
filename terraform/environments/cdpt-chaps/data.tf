#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "correspondence-handling-and-processing.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "selected" {
  provider     = aws.core-network-services
  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = true
}

data "aws_instances" "chaps_instances" {
  filter {
    name   = "tag:Environment"
    values = [local.application_data.accounts[local.environment].environment_name] 
  }

  instance_state = "running"
}