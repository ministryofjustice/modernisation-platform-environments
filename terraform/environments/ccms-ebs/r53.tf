#data "aws_route53_zone" "application-zone" {
#  provider = aws.core-network-services
#
#  name         = "laa.service.justice.gov.uk."
#  private_zone = false
#}


resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_ebs.private_ip]

}
resource "aws_route53_record" "ebsdb_cname" {
  #count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebsdb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsdb.fqdn]
}

/*
resource "aws_route53_record" "ebsappslb" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebsappslb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_eip.public-vip.public_dns]
}
*/