# resource "aws_route53_record" "database" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name_short}-db.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 900
#   records  = [aws_instance.database.private_ip]
# }

# resource "aws_route53_record" "concurrent_manager" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name_short}-cm.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 900
#   records  = [aws_instance.concurrent_manager.private_ip]
# }

# resource "aws_route53_record" "app1" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name_short}-app1.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 900
#   records  = [aws_instance.app1.private_ip]
# }

# resource "aws_route53_record" "app2" {
#   count    = contains(["development", "testing"], local.environment) ? 0 : 1
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_name_short}-app2.${data.aws_route53_zone.external.name}"
#   type     = "A"
#   ttl      = 900
#   records  = [aws_instance.app2.private_ip]
# }