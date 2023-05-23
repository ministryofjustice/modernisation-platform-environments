# Elastic IPs for EBS NLB

resource "aws_eip" "ebs_eip" {
  count = local.is-production ? 6 : 3
  vpc   = true

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-eip-${count.index + 1}", local.application_name, local.environment)) }
  )
}


# NLB for EBS

resource "aws_lb" "ebsapps_nlb" {
  name               = lower(format("nlb-%s-%s-ebs", local.application_name, local.environment))
  internal           = false
  load_balancer_type = "network"

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[0]
    allocation_id = aws_eip.ebs_eip[0].id
  }

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[1]
    allocation_id = aws_eip.ebs_eip[1].id
  }

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[2]
    allocation_id = aws_eip.ebs_eip[2].id
  }

  tags = merge(local.tags,
    { Name = lower(format("nlb-%s-%s-ebsapp", local.application_name, local.environment)) }
  )
}

resource "aws_lb_listener" "ebsnlb_listener" {
  load_balancer_arn = aws_lb.ebsapps_nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ebsnlb_tg.arn
  }
}

resource "aws_lb_target_group" "ebsnlb_tg" {
  name        = lower(format("tg-%s-%s-ebsnlb", local.application_name, local.environment))
  target_type = "alb"
  port        = "443"
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "ebsnlb" {
  target_group_arn = aws_lb_target_group.ebsnlb_tg.arn
  target_id        = aws_lb.ebsapps_lb.id
  port             = "443"
}



#### WEBGATE ####

# Elastic IPs for WebGate NLB

resource "aws_eip" "webgate_eip" {
  count = local.is-production ? 6 : 3
  vpc   = true

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-webgate-eip-${count.index + 1}", local.application_name, local.environment)) }
  )
}


# NLB for WebGate

resource "aws_lb" "webgate_nlb" {
  name               = lower(format("public-nlb-webgate"))
  internal           = false
  load_balancer_type = "network"

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[0]
    allocation_id = aws_eip.webgate_eip[0].id
  }

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[1]
    allocation_id = aws_eip.webgate_eip[1].id
  }

  subnet_mapping {
    subnet_id     = data.aws_subnets.shared-public.ids[2]
    allocation_id = aws_eip.webgate_eip[2].id
  }

  tags = merge(local.tags,
    { Name = lower(format("public-nlb-webgate")) }
  )
}

resource "aws_lb_listener" "webgatenlb_listener" {
  load_balancer_arn = aws_lb.webgate_nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webgatenlb_tg.arn
  }
}

resource "aws_lb_target_group" "webgatenlb_tg" {
  name        = lower(format("public-nlb-webgate-tg"))
  target_type = "alb"
  port        = "443"
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "webgatenlb" {
  target_group_arn = aws_lb_target_group.webgatenlb_tg.arn
  target_id        = aws_lb.webgate_public_lb.id
  port             = "443"
}