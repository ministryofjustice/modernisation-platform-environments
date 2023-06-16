resource "aws_route53_zone" "private" {
  name = "aws.dev.legalservices.gov.uk"
  vpc {
    vpc_id = data.aws_vpc.shared.id
  }
}