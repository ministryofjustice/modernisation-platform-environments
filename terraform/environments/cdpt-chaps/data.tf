#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "correspondence-handling-and-processing.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false  # Set to true if it's a Private Hosted Zone
}

data "aws_instances" "chaps_instances" {
  filter {
    name   = "tag:Name"
    values = ["cdpt-chaps-cluster-scaling-group"] 
  }

  filter {
    name = "instance-state-name"
    values = ["running"]
  }
}