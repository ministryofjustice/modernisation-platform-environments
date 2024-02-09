resource "aws_lb" "delius_microservices" {
  name                       = "delius-microservices"
  internal                   = true
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.delius_microservices_nlb.id]
  subnets                    = var.account_config.private_subnet_ids
  enable_deletion_protection = true
  tags = merge({
    Name = "delius-microservices-nlb"
  }, var.tags)
}

resource "aws_security_group" "delius_microservices_nlb" {
  name        = "delius-microservices-nlb"
  description = "Security group for delius microservices network load balancer"
  vpc_id      = var.account_info.vpc_id
  tags = merge({
    Name = "delius-microservices-nlb"
  }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "from_bastion" {
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  ip_protocol                  = "-1"
  security_group_id            = aws_security_group.delius_microservices_nlb.id
}

locals {
  unique_container_ports = distinct([for _, v in var.delius_microservice_configs : v.container_port])
}

resource "aws_lb_listener" "delius_microservices_listeners" {
  for_each = {
    for port in local.unique_container_ports : port => var.delius_microservice_configs
  }
  load_balancer_arn = aws_lb.delius_microservices.arn
  port              = each.key
  protocol          = "TCP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Delius microservices listener"
      status_code  = "200"
    }
  }
}