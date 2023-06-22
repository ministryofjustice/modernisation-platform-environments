resource "aws_route53_zone" "private" {
  name = "aws.dev.legalservices.gov.uk"
  vpc {
    vpc_id = data.aws_vpc.shared.id
  }
}

resource "aws_route53_vpc_association_authorization" "vpc_zone_association_auth" {
  # provider  = aws.default
  vpc_id    = data.aws_vpc.shared.id
  zone_id   = aws_route53_zone.private.id
}

resource "aws_route53_zone_association" "zone_association" {
  provider = aws.core-vpc
  vpc_id  = aws_route53_vpc_association_authorization.vpc_zone_association_auth.vpc_id
  zone_id = aws_route53_vpc_association_authorization.vpc_zone_association_auth.zone_id
}