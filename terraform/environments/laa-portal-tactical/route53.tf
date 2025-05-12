resource "aws_route53_zone" "private_uat" {
  name = "aws.uat.legalservices.gov.uk"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

# resource "aws_route53_zone_association" "private_uat" {
#   zone_id = aws_route53_zone.private_uat.zone_id
#   vpc_id  = module.vpc.vpc_id
# }

resource "aws_route53_record" "iadb" {
  zone_id  = aws_route53_zone.private_uat.zone_id
  name     = "db-portal-iadb.${aws_route53_zone.private_uat.name}" # db-portal-iadb.aws.[env].legalservices.gov.uk
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.iadb.address]
}

resource "aws_route53_record" "igdb" {
  zone_id  = aws_route53_zone.private_uat.zone_id
  name     = "db-portal-igdb.${aws_route53_zone.private_uat.name}" # db-portal-igdb.aws.dev.legalservices.gov.uk
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.igdb.address]
}