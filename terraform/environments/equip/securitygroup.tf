#Application Load balancer Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security Group for Application LoadBalancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-alb", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_internet_to_alb_traffic" {
  for_each          = local.application_data.internet_to_alb_rules
  description       = format("Internet to ALB traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.alb_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  #tfsec:ignore:AWS009
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_alb_to_citrix-adc_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc_rules
  description              = format("ALB to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

############################################################################

#Citrix ADC Security Group

resource "aws_security_group" "citrix_adc_mgmt" {
  name        = lower(format("secg-%s-%s-citrix-adc_mgmt", local.application_name, local.environment))
  description = "Security Group for Citrix ADC Management interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_mgmt", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_ctx_host_to_citrix-adc" {
  for_each                 = local.application_data.ctx_to_adc_rules
  description              = format("CTX host to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group" "citrix_adc_vip" {
  name        = lower(format("secg-%s-%s-citrix-adc_vip", local.application_name, local.environment))
  description = "Security Group for Citrix ADC VIP interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_vip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "egress_citrix_adc_vip_to_sf" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Spotfire for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "egress_citrix_adc_vip_to_equip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Equip for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_citrix_adc_vip_to_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_citrix_adc_vip_to_sf" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Spotfire for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "ingress_citrix_adc_vip_to_equip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Equip for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "ingress_citrix_adc_vip_to_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_sf_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Spotfire to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "egress_sf_to_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Spotfire traffic to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_sf_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Spotfire to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "ingress_sf_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Spotfire to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_equip_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Equip to Citrix ADC VIP for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "egress_equip_to_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Equip to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_equip_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Equip to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "ingress_equip_to_citrix_host" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Equip to Citrix Host for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix_host_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix ADC VIP traffic to Spotfire for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "ingress_citrix_host_to_citrix_adc_vip" {
  for_each                 = local.application_data.port_80_rules
  description              = format("Citrix host to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "ingress_alb_to_citrix-adc_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc_rules
  description              = format("ALB to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group" "citrix_adc_snip" {
  name        = lower(format("secg-%s-%s-citrix-adc_snip", local.application_name, local.environment))
  description = "Security Group for Citrix ADC SNIP interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_snip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "egress_citrix-adc_to_ctx-host" {
  for_each                 = local.application_data.adc_to_ctx_rules
  description              = format("Citrix ADC to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc_to_equip" {
  for_each                 = local.application_data.adc_to_equip_rules
  description              = format("Citrix ADC to Equip host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc_to_spotfire" {
  for_each                 = local.application_data.adc_to_spotfire_rules
  description              = format("Citrix ADC to Spotfire host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

############################################################################

#AWS Citrix Security Group

resource "aws_security_group" "aws_citrix_security_group" {
  name        = "aws_citrix_security_group"
  description = "Security Group for AWS_Citrix "
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-host", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_citrix-adc_to_ctx-host_traffic" {
  for_each                 = local.application_data.adc_to_ctx_rules
  description              = format("Citrix ADC SNIP to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "ingress_ctx_host_internal_traffic" {
  for_each                 = local.application_data.ctx_internal_rules
  description              = format("CTX host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_ctx_host_internal_traffic" {
  for_each                 = local.application_data.ctx_internal_rules
  description              = format("CTX host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_ctx_host_to_citrix-adc" {
  for_each                 = local.application_data.ctx_to_adc_rules
  description              = format("CTX host to Citrix ADC Management traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "egress_ctx_host_to_equip" {
  for_each                 = local.application_data.ctx_to_equip_rules
  description              = format("CTX host to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_ctx_host_to_spotfire" {
  for_each                 = local.application_data.ctx_to_spotfire_rules
  description              = format("CTX host to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "aws_citrix_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_citrix_security_group.id
}

############################################################################

#AWS Equip Security Group

resource "aws_security_group" "aws_equip_security_group" {
  name        = lower(format("secg-%s-%s-equip", local.application_name, local.environment))
  description = "Security Group for AWS_Equip"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-equip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_adc_to_equip_traffic" {
  for_each                 = local.application_data.adc_to_equip_rules
  description              = format("ADC SNIP to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "ingress_ctx_hosts_to_equip_traffic" {
  for_each                 = local.application_data.ctx_to_equip_rules
  description              = format("CTX host to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_spotfire_to_equip_traffic" {
  for_each                 = local.application_data.spotfire_to_equip_rules
  description              = format("Spotfire host to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "egress_equip_to_spotfire_traffic" {
  for_each                 = local.application_data.equip_to_spotfire_rules
  description              = format("Equip host to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "ingress_spotfire_internal_traffic" {
  for_each                 = local.application_data.spotfire_internal_rules
  description              = format("Spotfire internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

resource "aws_security_group_rule" "ingress_equip_internal_traffic" {
  for_each                 = local.application_data.equip_internal_rules
  description              = format("Equip host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
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
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-spotfire", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_adc_to_spotfire_traffic" {
  for_each                 = local.application_data.adc_to_spotfire_rules
  description              = format("ADC SNIP to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "ingress_ctx_hosts_to_spotfire_traffic" {
  for_each                 = local.application_data.ctx_to_spotfire_rules
  description              = format("CTX host to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_equip_to_spotfire_traffic" {
  for_each                 = local.application_data.equip_to_spotfire_rules
  description              = format("Equip host to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_spotfire_to_equip_traffic" {
  for_each                 = local.application_data.spotfire_to_equip_rules
  description              = format("Spotfire host to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "aws_spotfire_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_spotfire_security_group.id
}

############################################################################
#AWS Proxy Security Group

resource "aws_security_group" "aws_proxy_security_group" {
  name        = "aws_proxy_security_group"
  description = "Security Group for AWS_Proxy"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-proxy", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_hosts_to_proxies_traffic" {
  for_each                 = local.application_data.host_to_proxy_rules
  description              = format("All hosts to proxy server traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_proxy_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "aws_proxy_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_proxy_security_group.id
}

############################################################

#AWS Domain Security Group

resource "aws_security_group" "aws_domain_security_group" {
  name        = "aws_domain_security_group"
  description = "Security Group for AWS_Domain"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-domain-controller", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_hosts_to_domain_controller_traffic" {
  for_each                 = local.application_data.host_to_domain_controller_rules
  description              = format("All hosts to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "ingress_dns_endpoints_to_domain_controller_traffic" {
  for_each          = local.application_data.dns_endpoint_rules
  description       = format("DNS Endpoint to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_domain_security_group.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_domain_controller_to_all_hosts_traffic" {
  for_each                 = local.application_data.domain_controller_to_host_rules
  description              = format("Domain Controller to all host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "aws_domain_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks       = ["0.0.0.0/0", ]
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
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-all-hosts", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_domain_controller_to_all_hosts_traffic" {
  for_each                 = local.application_data.domain_controller_to_host_rules
  description              = format("Domain Controller to all host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.all_internal_groups.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

# cidr_blocks should be replaced with source_security_group_id, but open until confirmed with configuration team
resource "aws_security_group_rule" "egress_all_hosts_to_proxies" {
  for_each          = local.application_data.host_to_proxy_rules
  description       = format("All hosts to internet for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.all_internal_groups.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

## AWS Resolver Endpoint security group
resource "aws_security_group" "aws_dns_resolver" {
  provider    = aws.core-vpc
  name        = "dns_resolver"
  description = "Security Group for DNS resolver request"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ingress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.application_data.dns_endpoint_rules
  description       = format("VPC to DNS Endpoint traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.application_data.dns_endpoint_rules
  description       = format("DNS Endpoint to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
