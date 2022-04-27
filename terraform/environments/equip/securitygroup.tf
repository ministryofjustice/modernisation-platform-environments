#Application Load balancer Security Group
resource "aws_security_group" "alb_sg" {

  name        = "alb_sg"
  description = "Security Group for Application LoadBalancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = {
    Name = "alb_sg"
  }
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
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_alb_to_citrix-adc_traffic" {
  for_each                 = local.application_data.alb_to_citrix-adc_rules
  description              = format("ALB to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.alb_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.citrix_adc.id
}

############################################################################

#Citrix ADC Security Group

resource "aws_security_group" "citrix_adc" {
  name        = "citrix_adc"
  description = "Security Group for citrix_adc"
  vpc_id      = data.aws_vpc.shared.id
  tags = {
    Name = "citrix_adc"
  }
}

resource "aws_security_group_rule" "ingress_alb_to_citrix-adc_traffic" {
  for_each          = local.application_data.alb_to_citrix-adc_rules
  description       = format("ALB to Citrix ADC traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.citrix_adc.id
  to_port           = each.value.to_port
  type              = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "citrix_adc_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group_rule" "ingress_citrix-adc_to_ctx-host_traffic" {
  for_each          = local.application_data.adc_to_ctx_rules
  description       = format("Citrix ADC to Citrix host traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_citrix_security_group.id
  to_port           = each.value.to_port
  type              = "ingress"
  source_security_group_id = aws_security_group.citrix_adc.id
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

resource "aws_security_group_rule" "aws_citrix_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_citrix_security_group.id
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

resource "aws_security_group_rule" "aws_spotfire_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = ["0.0.0.0/0"]
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

  depends_on = [aws_security_group.all_internal_groups]
  tags = {
    Name = "aws_domain_security_group"
  }
}

resource "aws_security_group_rule" "ingress_hosts_to_domain_contoller_traffic" {
  for_each                 = local.application_data.host_to_domain_controller_rules
  description              = format("Windows host to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.all_internal_groups.id
}

resource "aws_security_group_rule" "ingress_dns_endpoints_to_domain_contoller_traffic" {
  for_each                 = local.application_data.dns_endpoint_rules
  description              = format("DNS Endpoint to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.aws_domain_security_group.id
  to_port                  = each.value.to_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.aws_dns_resolver.id
}

resource "aws_security_group_rule" "aws_domain_security_group_egress_1" {
  type        = "egress"
  protocol    = "-1"
  description = "Open all outbound ports"
  from_port   = 0
  to_port     = 0
  #tfsec:ignore:AWS009
  cidr_blocks = ["0.0.0.0/0",]
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

resource "aws_security_group_rule" "ingress_dns_endpoint_traffic" {
  for_each          = local.application_data.dns_endpoint_rules
  description       = format("Domain Controller internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_dns_endpoint_traffic" {
  for_each          = local.application_data.dns_endpoint_rules
  description       = format("Domain Controller internal traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}