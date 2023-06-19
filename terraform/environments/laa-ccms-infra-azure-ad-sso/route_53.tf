### LOADBALANCER
resource "aws_route53_record" "sg_ebs_vision_db_a_record" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.ebs_vision_db_lb.dns_name
    zone_id                = aws_lb.ebs_vision_db_lb.zone_id
    evaluate_target_health = true

  }
}


resource "aws_route53_record" "ebs_vision_db_lb_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebs-vision-db-lb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.sg_ebs_vision_db_a_record.fqdn]
}

## EBSDB
resource "aws_route53_record" "ebs_db_a_record" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "azure-ad-ebs-db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_vision_ebs.private_ip]

}

# new config
### LOADBALANCER
resource "aws_route53_record" "sg_ebs_vision_db_preclone_a_record" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.ebs_vision_db_lb_pre_clone.dns_name
    zone_id                = aws_lb.ebs_vision_db_lb_pre_clone.zone_id
    evaluate_target_health = true

  }
}


resource "aws_route53_record" "ebs_vision_db_lb_pre_clone_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebs-vision-db-lb-preclone"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.sg_ebs_vision_db_preclone_a_record.fqdn]
}

## EBSDB
resource "aws_route53_record" "ebs_db_preclone_a_record" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "azure-ad-ebs-preclone.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_vision_ebs_preclone.private_ip]

}



