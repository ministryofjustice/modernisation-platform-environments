
data "aws_route53_zone" "yjaf-inner" {
  provider = aws.core-network-services

  name         = "${local.environment}.yjaf"
  private_zone = true
}
