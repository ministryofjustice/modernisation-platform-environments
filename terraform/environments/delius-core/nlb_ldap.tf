# locals {
#   openldap_name     = format("%s-openldap", local.application_name)
#   openldap_nlb_name = format("%s-nlb", local.openldap_name)
#   openldap_nlb_tags = merge(
#     local.tags,
#     {
#       Name = local.openldap_nlb_name
#     }
#   )

#   openldap_protocol = "TCP"
# }
# resource "aws_lb" "ldap" {
#   name                       = local.openldap_nlb_name
#   internal                   = true
#   load_balancer_type         = "network"
#   subnets                    = data.aws_subnets.shared-private.ids
#   drop_invalid_header_fields = true
#   enable_deletion_protection = false

#   tags = local.openldap_nlb_tags
# }

# resource "aws_lb_listener" "ldap" {
#   load_balancer_arn = aws_lb.ldap.arn
#   port              = local.openldap_port
#   protocol          = local.openldap_protocol

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ldap.arn
#   }

#   tags = local.openldap_nlb_tags
# }

# resource "aws_lb_target_group" "ldap" {
#   name     = local.openldap_name
#   port     = local.openldap_port
#   protocol = local.openldap_protocol
#   vpc_id   = data.aws_vpc.shared.id

#   target_type          = "ip"
#   deregistration_delay = "30"
#   tags = merge(
#     local.tags,
#     {
#       Name = local.openldap_name
#     }
#   )
# }

# # Internal DNS name for LDAP load balancer - Internal LDAP consumers will use this
# resource "aws_route53_record" "ldap_dns_internal" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.inner.zone_id
#   name     = "ldap.${local.application_name}.${data.aws_route53_zone.inner.name}"
#   type     = "A"

#   alias {
#     name                   = aws_lb.ldap.dns_name
#     zone_id                = aws_lb.ldap.zone_id
#     evaluate_target_health = true # Could be true or false based on https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-alias.html#rrsets-values-alias-evaluate-target-health
#   }
# }
