data "aws_availability_zones" "available" {}

data "aws_route53_zone" "account_hosted_zone" {
  name         = local.environment_configuration.account_hosted_zone
  private_zone = false
}
