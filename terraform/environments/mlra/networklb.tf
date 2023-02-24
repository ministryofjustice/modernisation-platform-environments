# This creates a network load balancer listening on port 80 with a target of the internal ALB.

resource "aws_lb" "ingress-network-lb" {
  name                       = "${local.application_name}-network-lb"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  enable_deletion_protection = local.application_data.accounts[local.environment].nlb_prevent_deletion
  tags = {
    Name = "${local.application_name}-${local.environment}-ingress-network-lb"
  }
}

resource "aws_lb_listener" "lz-ingress" {
  load_balancer_arn = aws_lb.ingress-network-lb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-target.arn
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-lz-ingress"
  }
}

resource "aws_lb_target_group" "nlb-target" {
  name        = "${local.application_name}-${local.environment}-network-lb-tg"
  target_type = "alb"
  port        = "80"
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.shared.id
  # depends_on = [
  #   module.mlra-ecs,
  #   module.alb
  #   # module.albvars.load_balancer,
  #   # module.albvars.loab_balancer_listener,
  #   # module.albvars.target_group_name
  # ]
  tags = {
    Name = "${local.application_name}-${local.environment}-nlb-tg"
  }
}


resource "aws_lb_target_group_attachment" "nlb-target-attachment" {
  target_group_arn = aws_lb_target_group.nlb-target.arn
  target_id        = module.alb.load_balancer.id
}
