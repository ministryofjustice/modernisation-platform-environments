#Application Load balancer Security Group
resource "aws_security_group" "alb_sg" {

  name        = "alb_sg"
  description = "Security Group for Application LoadBalancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = {
    Name = "alb_sg"
  }
}

resource "aws_security_group_rule" "alb_sg_ingress_1" {
  type        = "ingress"
  protocol    = "tcp"
  description = "Web Traffic"
  from_port   = 80
  to_port     = 80
  #tfsec:ignore:AWS008
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_ingress_2" {
  type        = "ingress"
  protocol    = "tcp"
  description = "Web SSL Traffic"
  from_port   = 443
  to_port     = 443
  #tfsec:ignore:AWS008
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_egress" {
  type                     = "egress"
  protocol                 = "all"
  description              = "Egress Rule for alb_sg"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.alb_sg.id
}

############################################################################

#Citrix ADC Security Group

resource "aws_security_group" "citrix_adc" {
  name        = "citrix_adc"
  description = "Security Group for citrix_adc"
  vpc_id      = data.aws_vpc.shared.id

  depends_on = [aws_security_group.alb_sg]
  tags = {
    Name = "citrix_adc"
  }
}

resource "aws_security_group_rule" "citrix_adc_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web Traffic"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.citrix_adc.id
}

resource "aws_security_group_rule" "citrix_adc_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.citrix_adc.id
}

resource "aws_security_group_rule" "citrix_adc_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.citrix_adc.id
}


############################################################################

#AWS Citrix Security Group

resource "aws_security_group" "aws_citrix_security_group" {
  name        = "aws_citrix_security_group"
  description = "Security Group for AWS_Citrix "
  vpc_id      = data.aws_vpc.shared.id

  depends_on = [aws_security_group.citrix_adc]
  tags = {
    Name = "aws_citrix_security_group"
  }
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web Traffic"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "ICA TCP  Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_4" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "ICA UDP Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_5" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Citrixmaclient TCP Traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_ingress_6" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Citrixmaclient UDP Traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_ctx_host_internal_traffic" {
  for_each                 = local.application_data.ctx_internal_rules
  description              = format("CTX host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc.id
}

resource "aws_security_group_rule" "egress_ctx_host_internal_traffic" {
  for_each                 = local.application_data.ctx_internal_rules
  description              = format("CTX host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc.id
}

############################################################################

#AWS Equip Security Group

resource "aws_security_group" "aws_equip_security_group" {
  name        = "aws_equip_security_group"
  description = "Security Group for AWS_Equip"
  vpc_id      = data.aws_vpc.shared.id
  tags = {
    Name = "aws_equip_security_group"
  }
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}


resource "aws_security_group_rule" "aws_equip_security_group_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web TCP Traffic"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "ICA TCP Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_4" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Citrixmaclient TCP traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id

}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_5" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "HTTP TCP Traffic"
  from_port                = 8008
  to_port                  = 8008
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_6" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Custom TCP Traffic"
  from_port                = 16500
  to_port                  = 16509
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id

}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_7" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "CitrixUPPG TCP Traffic"
  from_port                = 7229
  to_port                  = 7229
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id

}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_8" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "webcache TCP Traffic"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id


}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_9" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "sink TCP Traffic"
  from_port                = 9
  to_port                  = 9
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_10" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "EPMAP TCP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_11" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "su-mit-tg TCP Traffic"
  from_port                = 89
  to_port                  = 89
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_12" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "9095 TCP Traffic"
  from_port                = 9095
  to_port                  = 9095
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_13" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "ICA UDP Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_14" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "citrixmaclient UDP traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_15" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "HTTP UDP Traffic"
  from_port                = 8008
  to_port                  = 8008
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_16" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Custom UDP Traffic"
  from_port                = 16500
  to_port                  = 16509
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_17" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "CitrixUPPG UDP Traffic"
  from_port                = 7229
  to_port                  = 7229
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_18" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "webcache UDP Traffic"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_19" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "sink UDP Traffic"
  from_port                = 9
  to_port                  = 9
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_20" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "EPMAP UDP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_21" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "su-mit-tg UDP Traffic"
  from_port                = 89
  to_port                  = 89
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_22" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "9095 UDP Traffic"
  from_port                = 9095
  to_port                  = 9095
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_23" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "RDP TCP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_24" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "RDP UDP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_equip_security_group_ingress_25" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_equip_security_group.id
}
resource "aws_security_group_rule" "aws_equip_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_equip_security_group.id
}

#####################################################################################################
#AWS SpotFire Security Group

resource "aws_security_group" "aws_spotfire_security_group" {
  name        = "aws_spotfire_security_group"
  description = "Security Group for AWS_SpotFire"
  vpc_id      = data.aws_vpc.shared.id

  tags = {
    Name = "aws_spotfire_security_group"
  }
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.citrix_adc.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}


resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web TCP Traffic"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "ICA TCP Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_4" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Citrixmaclient TCP traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_5" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "HTTP TCP Traffic"
  from_port                = 8008
  to_port                  = 8008
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_6" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Custom TCP Traffic"
  from_port                = 16500
  to_port                  = 16509
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_7" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "CitrixUPPG TCP Traffic"
  from_port                = 7229
  to_port                  = 7229
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_8" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "webcache TCP Traffic"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_9" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "sink TCP Traffic"
  from_port                = 9
  to_port                  = 9
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_10" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "EPMAP TCP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_11" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "su-mit-tg TCP Traffic"
  from_port                = 89
  to_port                  = 89
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_12" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "9095 TCP Traffic"
  from_port                = 9095
  to_port                  = 9095
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_13" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "RDP TCP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_14" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "ICA UDP Traffic"
  from_port                = 1494
  to_port                  = 1494
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_15" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "citrixmaclient UDP traffic"
  from_port                = 2598
  to_port                  = 2598
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_16" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "HTTP UDP Traffic"
  from_port                = 8008
  to_port                  = 8008
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_17" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Custom UDP Traffic"
  from_port                = 16500
  to_port                  = 16509
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_18" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "CitrixUPPG UDP Traffic"
  from_port                = 7229
  to_port                  = 7229
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_19" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "webcache UDP Traffic"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_20" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "sink UDP Traffic"
  from_port                = 9
  to_port                  = 9
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_21" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "EPMAP UDP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_22" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "su-mit-tg UDP Traffic"
  from_port                = 89
  to_port                  = 89
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_23" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "9095 UDP Traffic"
  from_port                = 9095
  to_port                  = 9095
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_24" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "RDP UDP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_ingress_25" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SSL Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
}



resource "aws_security_group_rule" "aws_spotfire_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_spotfire_security_group.id
}

############################################################################
#AWS Proxy Security Group

resource "aws_security_group" "aws_proxy_security_group" {
  name        = "aws_proxy_security_group"
  description = "Security Group for AWS_Proxy"
  vpc_id      = data.aws_vpc.shared.id

  depends_on = [aws_security_group.all_internal_groups]

  tags = {
    Name = "aws_proxy_security_group"
  }
}

resource "aws_security_group_rule" "aws_proxy_security_group_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Web TCP Traffic"
  from_port                = 80
  to_port                  = 80
  depends_on               = [aws_security_group.all_internal_groups]
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_proxy_security_group.id

}

resource "aws_security_group_rule" "aws_proxy_security_group_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SSL TCP Traffic"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_proxy_security_group.id
}

resource "aws_security_group_rule" "aws_proxy_security_group_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "SAG TCP Traffic"
  from_port                = 4952
  to_port                  = 65535
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_proxy_security_group.id
}

resource "aws_security_group_rule" "aws_proxy_security_group_ingress_4" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "SAG UDP Traffic"
  from_port                = 4952
  to_port                  = 65535
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_proxy_security_group.id
}


resource "aws_security_group_rule" "aws_proxy_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_proxy_security_group.id
}

############################################################

#AWS Domain Security Group

resource "aws_security_group" "aws_domain_security_group" {
  name        = "aws_domain_security_group"
  description = "Security Group for AWS_Domain"
  vpc_id      = data.aws_vpc.shared.id

  depends_on = [aws_security_group.all_internal_groups]
  tags = {
    Name = "aws_domain_security_group"
  }
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "kerberos TCP Traffic"
  from_port                = 88
  to_port                  = 88
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "RPC TCP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Netbios TCP Traffic"
  from_port                = 139
  to_port                  = 139
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_4" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "microsoft-ds TCP Traffic"
  from_port                = 445
  to_port                  = 445
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_5" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "LDAP TCP traffic"
  from_port                = 389
  to_port                  = 389
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_6" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "LDAP UDP Traffic"
  from_port                = 389
  to_port                  = 389
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_7" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "DNS UDP Traffic"
  from_port                = 53
  to_port                  = 53
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_8" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "High Ports TCP Traffic"
  from_port                = 49152
  to_port                  = 65535
  source_security_group_id = aws_security_group.all_internal_groups.id
  security_group_id        = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_9" {
  description       = "Allow resolver endpoint to send DNS requests to DC"
  type              = "ingress"
  protocol          = "udp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_ingress_10" {
  description       = "Allow resolver endpoint to send DNS requests to DC"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "aws_domain_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_domain_security_group.id
}

## Domain Controller internal traffic
## https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/config-firewall-for-ad-domains-and-trusts

resource "aws_security_group_rule" "ingress_domain_controller_internal_traffic" {
  for_each                 = local.application_data.domain_controller_internal_rules
  description              = format("Domain Controller internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "egress_domain_controller_internal_traffic" {
  for_each                 = local.application_data.domain_controller_internal_rules
  description              = format("Domain Controller internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

#############################################################

#All Internal Security Group

resource "aws_security_group" "all_internal_groups" {
  name        = "all_internal_groups"
  description = "Security Group for all_internal_groups"
  vpc_id      = data.aws_vpc.shared.id

  tags = {
    Name = "all_internal_groups"
  }
}

resource "aws_security_group_rule" "all_internal_groups_ingress_0" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "EPMAP TCP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_1" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Netbios TCP Traffic"
  from_port                = 137
  to_port                  = 139
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_2" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "microsoft-ds TCP Traffic"
  from_port                = 445
  to_port                  = 445
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_3" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "LDAP TCP traffic"
  from_port                = 389
  to_port                  = 389
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_4" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "LDAPS TCP Traffic"
  from_port                = 636
  to_port                  = 636
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}


resource "aws_security_group_rule" "all_internal_groups_ingress_5" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "MSft-gc TCP Traffic"
  from_port                = 3268
  to_port                  = 3269
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_6" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "kerberos TCP Traffic"
  from_port                = 88
  to_port                  = 88
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_7" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "DNS TCP Traffic"
  from_port                = 53
  to_port                  = 53
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}
resource "aws_security_group_rule" "all_internal_groups_ingress_8" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Wins TCP Traffic"
  from_port                = 1512
  to_port                  = 1512
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_9" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "Nameserver TCP Traffic"
  from_port                = 42
  to_port                  = 42
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_10" {
  type                     = "ingress"
  protocol                 = "tcp"
  description              = "RDP TCP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_11" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "EPMAP UDP Traffic"
  from_port                = 135
  to_port                  = 135
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_12" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Netbios UDP Traffic"
  from_port                = 137
  to_port                  = 139
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_13" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "microsoft-ds UDP Traffic"
  from_port                = 445
  to_port                  = 445
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_14" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "LDAP UDP Traffic"
  from_port                = 389
  to_port                  = 389
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_15" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "LDAPS UDP Traffic"
  from_port                = 636
  to_port                  = 636
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_16" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "MSft-gc UDP Traffic"
  from_port                = 3268
  to_port                  = 3269
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_17" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "kerberos UDP Traffic"
  from_port                = 88
  to_port                  = 88
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_18" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "DNS UDP Traffic"
  from_port                = 53
  to_port                  = 53
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_19" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Wins UDP Traffic"
  from_port                = 1512
  to_port                  = 1512
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_20" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "Nameserver UDP Traffic"
  from_port                = 42
  to_port                  = 42
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_ingress_21" {
  type                     = "ingress"
  protocol                 = "udp"
  description              = "RDP UDP Traffic"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = aws_security_group.aws_domain_security_group.id
  security_group_id        = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "all_internal_groups_egress" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.all_internal_groups.id
}

## AWS Resolver Endpoint security group
resource "aws_security_group" "aws_dns_resolver" {
  provider    = aws.core-vpc
  name        = "dns_resolver"
  description = "Security Group for DNS resolver request"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "allow_tcp_53_in" {
  provider          = aws.core-vpc
  description       = "Allow resolver endpoint to receive DNS requests"
  from_port         = 53
  protocol          = "TCP"
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = 53
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "allow_udp_53_in" {
  provider          = aws.core-vpc
  description       = "Allow resolver endpoint to receive DNS requests"
  from_port         = 53
  protocol          = "UDP"
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = 53
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "allow_tcp_53_out" {
  provider          = aws.core-vpc
  description       = "Allow resolver endpoint to forward DNS requests"
  from_port         = 53
  protocol          = "TCP"
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = 53
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "allow_udp_53_out" {
  provider          = aws.core-vpc
  description       = "Allow resolver endpoint to forward DNS requests"
  from_port         = 53
  protocol          = "UDP"
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = 53
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}