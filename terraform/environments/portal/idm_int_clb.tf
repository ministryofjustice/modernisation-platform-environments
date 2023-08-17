resource "aws_elb" "idm_lb" {
  name            = "${local.application_name}-internal-lb-idm"
  internal        = true
  idle_timeout    = 3600
  security_groups = [aws_security_group.internal_idm_sg.id]
  subnets         = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]



  access_logs {
    bucket        = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
    bucket_prefix = "${local.application_name}-internal-lb-idm"
    enabled       = true
  }

  listener {
    instance_port     = 1389
    instance_protocol = "TCP"
    lb_port           = 1389
    lb_protocol       = "TCP"
  }


  listener {
    instance_port     = 1636
    instance_protocol = "TCP"
    lb_port           = 1636
    lb_protocol       = "TCP"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    target              = "TCP:1389"
    interval            = 15
  }
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-internal-lb-idm"
    }
  )
}




resource "aws_elb_attachment" "idm_attachment1" {
  elb      = aws_elb.idm_lb.id
  instance = aws_instance.idm_instance_1.id
}

resource "aws_elb_attachment" "idm_attachment2" {
  count    = contains(["development", "testing"], local.environment) ? 0 : 1
  elb      = aws_elb.idm_lb.id
  instance = aws_instance.idm_instance_2[0].id
}

resource "aws_security_group" "internal_idm_sg" {
  name        = "${local.application_name}-${local.environment}-idm-internal-elb-security-group"
  description = "${local.application_name} internal elb security group"
  vpc_id      = data.aws_vpc.shared.id
}


resource "aws_vpc_security_group_ingress_rule" "internal_inbound" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 1389
  ip_protocol       = "tcp"
  to_port           = 1389
}


resource "aws_vpc_security_group_ingress_rule" "internal_inbound1" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 1636
  ip_protocol       = "tcp"
  to_port           = 1636
}


resource "aws_vpc_security_group_egress_rule" "internal_idm_lb_outbound" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################################################
# Landing Zone Inbound for Integration
################################################

resource "aws_vpc_security_group_ingress_rule" "internal_lz" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = local.application_data.accounts[local.environment].landing_zone_vpc_cidr
  from_port         = 1389
  ip_protocol       = "tcp"
  to_port           = 1389
}

resource "aws_vpc_security_group_ingress_rule" "internal_lz1" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = local.application_data.accounts[local.environment].landing_zone_vpc_cidr
  from_port         = 1636
  ip_protocol       = "tcp"
  to_port           = 1636
}
