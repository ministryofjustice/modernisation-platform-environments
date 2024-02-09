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
