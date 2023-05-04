# Elastic IPs for NLB

resource "aws_eip" "ebs_eip" {
  count    = 3
  vpc      = true

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-eip-${count.index+1}", local.application_name, local.environment)) }
  )  
}


# NLB for EBS

resource "aws_lb" "ebsapps_nlb" {
  name               = lower(format("nlb-%s-%s-ebsapp", local.application_name, local.environment))
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.nlb_log_prefix_ebsapp
    enabled = true
  }

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
    target_group_arn = aws_lb_target_group.ebsnlb_tg.id
  }
}

resource "aws_lb_target_group" "ebsnlb_tg" {
  name     = lower(format("tg-%s-%s-ebsnlb", local.application_name, local.environment))
  port     = "443"
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "ebsnlb" {
  target_group_arn = aws_lb_target_group.ebsnlb_tg.arn
  target_id        = aws_lb.ebsapps_lb.arn
  port             = "443"
}


