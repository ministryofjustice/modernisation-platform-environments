# NLB for EBS DB
resource "aws_lb" "ebsdb_nlb" {
  name                             = lower(format("nlb-%s-db", local.application_name))
  internal                         = true
  load_balancer_type               = "network"
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  subnets                          = data.aws_subnets.shared-private.ids
  security_groups                  = [aws_security_group.sg_ebsdb_nlb.id]
  tags = merge(local.tags,
    { Name = lower(format("nlb-%s-db", local.application_name)) }
  )
}

resource "aws_lb_target_group" "ebsdb_nlb" {
  name                 = lower(format("tg-%s-db", local.application_name))
  port                 = local.application_data.accounts[local.environment].tg_db_port
  protocol             = "TCP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}

resource "aws_lb_target_group_attachment" "ebsdb" {
  target_group_arn = aws_lb_target_group.ebsdb_nlb.arn
  target_id        = aws_instance.ec2_oracle_ebs.id
  port             = local.application_data.accounts[local.environment].tg_db_port
}

resource "aws_lb_listener" "ebsdbnlb_listener" {
  load_balancer_arn = aws_lb.ebsdb_nlb.id
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = aws_acm_certificate_validation.external.certificate_arn
  default_action {
    target_group_arn = aws_lb_target_group.ebsdb_nlb.id
    type             = "forward"
  }
}
