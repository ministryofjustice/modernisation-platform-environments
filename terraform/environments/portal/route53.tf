resource "aws_route53_zone" "private" {
  name = "aws.dev.legalservices.gov.uk"
  vpc {
    vpc_id = data.aws_vpc.shared.id
  }
}

resource "aws_route53_vpc_association_authorization" "vpc_zone_association_auth" {
  provider  = aws.core-vpc
  vpc_id    = aws_vpc.core-vpc.id
  zone_id   = aws_route53_zone.private.id
}
