# ## EBSDB
# resource "aws_route53_record" "ebsdb" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name    = "ccms-ebs-db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.ec2_oracle_ebs.private_ip]
# }
