data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "service" {
  provider     = aws.core-network-services
  name         = local.is-production == false ? "${local.environment}.managed-file-transfer.service.justice.gov.uk" : "managed-file-transfer.service.justice.gov.uk"
  private_zone = false
}
