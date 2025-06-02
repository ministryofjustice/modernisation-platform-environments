# EBS DB
resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-db-sandbox.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_oracle_ebs.private_ip]
}

# EBS Apps
resource "aws_route53_record" "ebsapps" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].ebsapps_no_instances
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-app${count.index + 1}-sandbox.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_ebsapps[count.index].private_ip]
}

# EBS ALB
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebs-sandbox.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebsapps_lb.dns_name
    zone_id                = aws_lb.ebsapps_lb.zone_id
    evaluate_target_health = true
  }
}
