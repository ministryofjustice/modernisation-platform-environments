# locals {
#   nlb_arn       = module.vcms_service.nlb_arn
#   nlb_dns_name  = module.vcms_service.nlb_dns_name
#   nlb_r53_fqdn  = module.vcms_service.nlb_service_r53_record
#   nlb_tg_map    = module.vcms_service.nlb_target_group_arn_map
# }


# resource "aws_lb_listener" "listener" {
#   load_balancer_arn = locals.nlb_arn
#   port              = 443
#   protocol          = "TLS"
#   certificate_arn   = aws_acm_certificate.external.arn

#   default_action {
#     target_group_arn = aws_lb_target_group.target_group_fargate.id
#     type             = "forward"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = local.application_name
#     }
#   )
# }

# resource "aws_lb_target_group" "target_group_fargate" {
#   name                 = local.application_name
#   port                 = local.app_port
#   protocol             = "TCP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "ip"
#   deregistration_delay = 30

#   health_check {
#     port                = local.app_port
#     protocol            = "TCP"
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#     interval            = 30
#     timeout             = 10
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = local.application_name
#     }
#   )
# }
