resource "aws_vpc_endpoint_service" "HomeOffice" {
  count                      = local.is-production == true ? 1 : 0
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.ppud_internal_nlb.arn]
  tags = {
    Name = "HomeOffice-Endpoint"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "HomeOffice" {
  count                   = local.is-production == true ? 1 : 0
  vpc_endpoint_service_id = aws_vpc_endpoint_service.HomeOffice.id
  principal_arn           = "arn:aws:iam::518406511151:root"
}

resource "aws_lb" "ppud_internal_nlb" {
  count              = local.is-production == true ? 1 : 0
  name               = "ppud-internal-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  security_groups    = [aws_security_group.PPUD-ALB.id]
  enable_deletion_protection = false    # change it to true

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "nlb_forward_rule" {
  count             = local.is-production == true ? 1 : 0
  load_balancer_arn = aws_lb.ppud_internal_nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
 count     = local.is-production == true ? 1 : 0
  name        = "nlb-target-group"
  port        = "443"
  protocol    = "TCP"
  target_type = "alb"   # As type is ALB, you can't modify the target group attributes and will use their default values.
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "alb_attachment" {
  count     = local.is-production == true ? 1 : 0
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = aws_lb.PPUD-internal-ALB.id
  port             = "443"
  depends_on = [
    aws_lb_listener.nlb_forward_rule,
  ]
}