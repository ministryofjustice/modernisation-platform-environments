
data "aws_route53_zone" "yjaf-inner" {
  provider = aws.core-network-services

  name         = "development.yjaf"
  private_zone = true
}
