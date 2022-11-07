# This creates a network load balancer listening on port 80 with a target of the internal ALB.

locals {
  lz_vpc_cidr = local.application_data.accounts[local.environment].lz_vpc_cidr
}

resource "aws_lb" "ingress-network-lb" {
  name               = "ingress-network-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  enable_deletion_protection = true
}

resource "aws_lb_listener" "lz-ingress" {
  load_balancer_arn = aws_lb.ingress-network-lb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

resource "aws_lb_target_group" "alb-target" {
  name        = "alb-target"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_lb_target_group_attachment" "alb-target-attachment" {
  target_group_arn = aws_lb_target_group.alb-target.arn
  target_id = module.alb.load_balancer.id
}