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

resource "aws_security_group_rule" "egress_alb_to_citrix-adc-vip_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc-vip_rules
  description              = format("ALB to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "egress_alb_to_citrix-adc-snip_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc-snip_rules
  description              = format("ALB to Citrix ADC SNIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "egress_alb_to_ctx_host_traffic" {
  for_each                 = local.application_data.alb_to_ctx_rules
  description              = format("ALB to CTX traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_alb_to_equip_host_traffic" {
  for_each                 = local.application_data.alb_to_equip_rules
  description              = format("ALB to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_alb_to_spotfire_host_traffic" {
  for_each                 = local.application_data.alb_to_spotfire_rules
  description              = format("ALB to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

############################################################################

#Citrix ADC MGMT Security Group

resource "aws_security_group" "citrix_adc_mgmt" {
  name        = lower(format("secg-%s-%s-citrix-adc_mgmt", local.application_name, local.environment))
  description = "Security Group for Citrix ADC Management interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_mgmt", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_ctx_host_to_citrix-adc-mgmt" {
  for_each                 = local.application_data.ctx_to_adc-mgmt_rules
  description              = format("CTX host to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "ingress_proxy_host_to_citrix-adc-mgmt" {
  for_each                 = local.application_data.proxy_to_adc-mgmt_rules
  description              = format("Proxy host to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_proxy_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-mgmt_to_ctx_host" {
  for_each                 = local.application_data.adc-mgmt_to_ctx_rules
  description              = format("Citrix ADC MGMT traffic to CTX hosts for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-mgmt_to_domain_controllers" {
  for_each                 = local.application_data.adc-mgmt_to_domain_controller_rules
  description              = format("Citrix ADC MGMT traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-mgmt_to_equip" {
  for_each                 = local.application_data.adc-mgmt_to_equip_rules
  description              = format("Citrix ADC MGMT traffic to Equip for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-mgmt_to_sf" {
  for_each                 = local.application_data.adc-mgmt_to_spotfire_rules
  description              = format("Citrix ADC MGMT traffic to Spotfire for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_mgmt.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
}

############################################################################

#Citrix ADC VIP Security Group

resource "aws_security_group" "citrix_adc_vip" {
  name        = lower(format("secg-%s-%s-citrix-adc_vip", local.application_name, local.environment))
  description = "Security Group for Citrix ADC VIP interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_vip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_alb_to_citrix-adc-vip_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc-vip_rules
  description              = format("ALB to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_internet_to_citrix-adc-vip_traffic" {
  for_each          = local.application_data.internet_to_adc-vip_rules
  description       = format("Internet to Citrix ADC VIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.citrix_adc_vip.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_ctx-host_to_citrix-adc-vip_traffic" {
  for_each                 = local.application_data.ctx_to_adc-vip_rules
  description              = format("Citrix Host traffic to ADC VIP for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-vip_to_domain_controller_traffic" {
  for_each                 = local.application_data.adc-vip_to_domain_controller_rules
  description              = format("Citrix ADC VIP traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_vip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

############################################################################

#Inbound security group for azures connections

resource "aws_security_group" "azures_ingres" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = lower(format("secg-%s-%s-azures-ingress", local.application_name, local.environment))
  description = "Security Group for azures ingress connections"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-azures-ingress", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_azures_traffic" {
  for_each          = local.application_data.azures_endpoint_rules
  description       = format("Ingress rules for azures connections %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.azures_ingres.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/24"]
}


############################################################################

#Citrix ADC SNIP Security Group

resource "aws_security_group" "citrix_adc_snip" {
  name        = lower(format("secg-%s-%s-citrix-adc_snip", local.application_name, local.environment))
  description = "Security Group for Citrix ADC SNIP interface"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-adc_snip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_alb_to_citrix-adc-snip_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc-snip_rules
  description              = format("ALB to Citrix ADC SNIP traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_ctx-host_to_citrix-adc-snip_traffic" {
  for_each                 = local.application_data.ctx_to_adc-snip_rules
  description              = format("Citrix Host traffic to ADC SNIP for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-snip_to_ctx-host" {
  for_each                 = local.application_data.adc-snip_to_ctx_rules
  description              = format("Citrix ADC SNIP to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_citrix_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-snip_to_domain_controller_traffic" {
  for_each                 = local.application_data.adc-snip_to_domain_controller_rules
  description              = format("Citrix ADC SNIP traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-snip_to_equip" {
  for_each                 = local.application_data.adc-snip_to_equip_rules
  description              = format("Citrix ADC to Equip host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.citrix_adc_snip.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_citrix-adc-snip_to_spotfire" {
  for_each                 = local.application_data.adc-snip_to_spotfire_rules
  description              = format("Citrix ADC SNIP to Spotfire host traffic for %s %d", each.value.protocol, each.value.from_port)
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
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = "aws_citrix_security_group"
  description = "Security Group for AWS_Citrix "
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-citrix-host", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_citrix-adc-mgmt_to_ctx-host_traffic" {
  for_each                 = local.application_data.adc-mgmt_to_ctx_rules
  description              = format("Citrix ADC MGMT to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-snip_to_ctx-host_traffic" {
  for_each                 = local.application_data.adc-snip_to_ctx_rules
  description              = format("Citrix ADC SNIP to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "ingress_alb_to_ctx-host_traffic" {
  for_each                 = local.application_data.alb_to_ctx_rules
  description              = format("ALB to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
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

resource "aws_security_group_rule" "egress_ctx_host_to_citrix-adc-mgmt" {
  for_each                 = local.application_data.ctx_to_adc-mgmt_rules
  description              = format("CTX host to Citrix ADC Management traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "egress_ctx_host_to_citrix-adc-vip" {
  for_each                 = local.application_data.ctx_to_adc-vip_rules
  description              = format("CTX host traffic to ADC VIP interface for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
}

resource "aws_security_group_rule" "egress_ctx_host_to_citrix-adc-snip" {
  for_each                 = local.application_data.ctx_to_adc-snip_rules
  description              = format("CTX host traffic to ADC SNIP interface for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_citrix_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
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

############################################################################

#AWS Equip Security Group

resource "aws_security_group" "aws_equip_security_group" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = lower(format("secg-%s-%s-equip", local.application_name, local.environment))
  description = "Security Group for AWS_Equip"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-equip", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_alb_to_equip_traffic" {
  for_each                 = local.application_data.alb_to_equip_rules
  description              = format("ALB to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-mgmt_to_equip_traffic" {
  for_each                 = local.application_data.adc-mgmt_to_equip_rules
  description              = format("ADC MGMT to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-snip_to_equip_traffic" {
  for_each                 = local.application_data.adc-snip_to_equip_rules
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

resource "aws_security_group_rule" "ingress_soc_to_equip_traffic" {
  for_each                 = local.application_data.soc_to_equip_rules
  description              = format("SOC traffic to Equip Hosts for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_soc_security_group.id
}

resource "aws_security_group_rule" "egress_equip_internal_traffic" {
  for_each                 = local.application_data.equip_internal_rules
  description              = format("Equip host internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_equip_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}

resource "aws_security_group_rule" "egress_equip_to_SES_traffic" {
  for_each          = local.application_data.equip_to_aws_ses_rules
  description       = format("Equip host to SES traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_equip_security_group.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
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

#trivy:ignore:avd-aws-0104
resource "aws_security_group_rule" "aws_equip_security_group_egress_1" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.aws_equip_security_group.id
}

#####################################################################################################
#AWS SpotFire Security Group

resource "aws_security_group" "aws_spotfire_security_group" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = "aws_spotfire_security_group"
  description = "Security Group for AWS_SpotFire"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-spotfire", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_alb_to_spotfire_traffic" {
  for_each                 = local.application_data.alb_to_spotfire_rules
  description              = format("ALB to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-mgmt_to_spotfire_traffic" {
  for_each                 = local.application_data.adc-mgmt_to_spotfire_rules
  description              = format("ADC MGMT to Equip traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-snip_to_spotfire_traffic" {
  for_each                 = local.application_data.adc-snip_to_spotfire_rules
  description              = format("ADC SNIP to Spotfire traffic for %s %d", each.value.protocol, each.value.from_port)
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

resource "aws_security_group_rule" "egress_spotfire_internal_traffic" {
  for_each                 = local.application_data.spotfire_internal_rules
  description              = format("Spotfire internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_spotfire_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_spotfire_security_group.id
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

#trivy:ignore:avd-aws-0104
resource "aws_security_group_rule" "aws_spotfire_security_group_egress_1" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  protocol          = "-1"
  description       = "Open all outbound ports"
  from_port         = 0
  to_port           = 0
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

resource "aws_security_group_rule" "ingress_domain_controllers_to_proxies_traffic" {
  for_each                 = local.application_data.domain_controller_to_proxy_rules
  description              = format("Domain Controller to proxy server traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_proxy_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_domain_security_group.id
}

resource "aws_security_group_rule" "egress_proxy_host_to_citrix-adc-mgmt" {
  for_each                 = local.application_data.proxy_to_adc-mgmt_rules
  description              = format("Proxy host to Citrix ADC Management traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_proxy_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

#trivy:ignore:avd-aws-0104
resource "aws_security_group_rule" "aws_proxy_security_group_egress_1" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  protocol          = "-1"
  description       = "Open all outbound ports"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_proxy_security_group.id
}

############################################################

#AWS Domain Security Group

resource "aws_security_group" "aws_domain_security_group" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = "aws_domain_security_group"
  description = "Security Group for AWS_Domain"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-domain-controller", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_citrix-adc-mgmt_to_domain_controller_traffic" {
  for_each                 = local.application_data.adc-mgmt_to_domain_controller_rules
  description              = format("ADC MGMT to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_mgmt.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-snip_to_domain_controller_traffic" {
  for_each                 = local.application_data.adc-snip_to_domain_controller_rules
  description              = format("Citrix ADC SNIP traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_snip.id
}

resource "aws_security_group_rule" "ingress_citrix-adc-vip_to_domain_controller_traffic" {
  for_each                 = local.application_data.adc-vip_to_domain_controller_rules
  description              = format("Citrix ADC VIP traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.citrix_adc_vip.id
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

resource "aws_security_group_rule" "egress_domain_controller_to_proxies" {
  for_each                 = local.application_data.domain_controller_to_proxy_rules
  description              = format("Domain Controller to Proxy traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_proxy_security_group.id
}

#trivy:ignore:avd-aws-0104
resource "aws_security_group_rule" "aws_domain_security_group_egress_1" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  protocol          = "-1"
  description       = "Open all outbound ports"
  from_port         = 0
  to_port           = 0
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

resource "aws_security_group_rule" "egress_all_hosts_to_domain_controller_traffic" {
  for_each                 = local.application_data.host_to_domain_controller_rules
  description              = format("Host traffic to Domain Controllers for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.all_internal_groups.id
  to_port                  = each.value.to_port
  type                     = "egress"
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

############################################################

#AWS SOC Security Group

resource "aws_security_group" "aws_soc_security_group" {
  name        = "soc_security_group"
  description = "Security Group for SOC instances"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("secg-%s-%s-soc", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "egress_soc_to_equip_traffic" {
  for_each                 = local.application_data.soc_to_equip_rules
  description              = format("SOC traffic to Equip Hosts for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_soc_security_group.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.aws_equip_security_group.id
}