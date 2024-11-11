#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "correspondence-handling-and-processing.service.justice.gov.uk."
  private_zone = false
}

data "aws_instances" "chaps_instances" {
  filter {
    name   = "tag:Environment"
    values = [local.application_data.accounts[local.environment].environment_name] 
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}