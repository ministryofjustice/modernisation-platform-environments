resource "aws_security_group" "nextcloud_alb_sg" {
  name        = "delius-mis-nextcloud-alb-sg"
  description = "Security group for the nextcloud alb"
  vpc_id      = var.account_info.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nextcloud_ecs_service" {
  security_group_id            = aws_security_group.nextcloud_alb_sg.id
  description                  = "Allow traffic from the nextcloud alb to the nextcloud ecs service"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "TCP"
  referenced_security_group_id = module.nextcloud_service.service_security_group_id
}
