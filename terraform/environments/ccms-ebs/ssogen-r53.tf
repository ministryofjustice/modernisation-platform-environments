#########################################
# SSOGEN Internal Load Balancer DNS Records
#########################################

# Non-prod SSOGEN ALB record
resource "aws_route53_record" "ssogen_internal_alb" {
  count    = local.is-development || local.is-test ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccmsebs-sso"
  type    = "A"

  alias {
    name                   = aws_lb.ssogen_alb[count.index].dns_name
    zone_id                = aws_lb.ssogen_alb[count.index].zone_id
    evaluate_target_health = true
  }
}

data "aws_instance" "ssogen_primary_details" {
  count    = local.is-development || local.is-test ? 1 : 0

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.ssogen-scaling-group-primary[count.index].name]
  }
  filter {
    name   = "tag:Name"
    values = [lower(format("ccms-%s-%s-as1", local.application_name_ssogen, local.environment))]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "ssogen_secondary_details" {
  count    = local.is-development || local.is-test ? 1 : 0

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.ssogen-scaling-group-secondary[count.index].name]
  }
  filter {
    name   = "tag:Name"
    values = [lower(format("ccms-%s-%s-as2", local.application_name_ssogen, local.environment))]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

resource "aws_route53_record" "ssogen_primary" {
  count    = local.is-development || local.is-test ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  #name    = "ccms-ebs-db.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  name    = "ccms-${local.application_name_ssogen}-as1.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [data.aws_instance.ssogen_primary_details[count.index].private_ip]
}

resource "aws_route53_record" "ssogen_secondary" {
  count    = local.is-development || local.is-test ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  #name    = "ccms-ebs-db.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  name    = "ccms-${local.application_name_ssogen}-as2.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [data.aws_instance.ssogen_secondary_details[count.index].private_ip]
}
  