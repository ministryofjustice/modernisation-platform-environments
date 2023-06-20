resource "aws_route53_zone" "private" {
  name = "aws.dev.legalservices.gov.uk"
  vpc {
    vpc_id = [aws_vpc.core-vpc.id]
  }
}

