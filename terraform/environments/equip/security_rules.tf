variable "security_group_inbound_ports_dc" {
  type        = list(number)
  description = "list of DC controller ports"
  default     = [135, 135, 137, 137, 138, 139, 445, 445, 389, 389, 636, 3268, 3269, 88, 88, 53, 53, 1512, 1512, 42, 42]
}

variable "security_group_rule_description_dc" {
  type        = list(string)
  description = "list of DC controller description"
  default     = ["RPC endpoint mapper_TCP", "RPC endpoint mapper_UDP", "NetBIOS name Service_TCP", "NetBIOS name Service_UDP", "NetBIOS datagram service", "NetBIOS session service", "SMB over IP (Microsoft-DS)_TCP", "SMB over IP (Microsoft-DS)_UDP", "LDAP_TCP", "LDAP_UDP", "LDAP over SSL", "Global catalogue LDAP", "Global catalogue LDAP over SSL", "Kerberos_TCP", "Kerberos_UDP", "DNS_TCP", "DNS_UDP", "WINS resolution_TCP", "WINS resolution_UDP", "WINS replication_TCP", "WINS replication_UDP"]
}

variable "security_group_rule_protocol_dc" {
  type        = list(string)
  description = "list of DC controller protocols"
  default     = ["TCP", "UDP", "TCP", "UDP", "UDP", "TCP", "TCP", "UDP", "TCP", "UDP", "TCP", "TCP", "TCP", "TCP", "UDP", "TCP", "UDP", "TCP", "UDP", "TCP", "UDP"]
}

resource "aws_security_group_rule" "ingress_rules" {
  count             = length(var.security_group_inbound_ports_dc)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_dc[count.index]
  to_port           = var.security_group_inbound_ports_dc[count.index]
  protocol          = var.security_group_rule_protocol_dc[count.index]
  cidr_blocks       = ["${join(" ", module.win2016_multiple["COR-A-DC01"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-DC02"].private_ip)}/32"]
  description       = var.security_group_rule_description_dc[count.index]
  security_group_id = aws_security_group.ec2_security_dc.id
}

##############################################################################################

variable "security_group_inbound_ports_adc" {
  type        = list(number)
  description = "list of ADC ports"
  default     = [1494, 1494, 2598, 2589, 443, 443, 8008, 7229, 8080, 9, 135, 80, 89, 9095, 16500, 16501, 16502, 16503, 16504, 16505, 16506, 16507, 16508, 16509]
}
variable "security_group_rule_description_adc" {
  type        = list(string)
  description = "ADC Description "
  default     = ["TCP_1494", "UDP_1494", "TCP_2598", "UDP_2589", "TCP_443", "UDP_443", "TCP_8008", "TCP_7229", "TCP_8080", "UDP_9", "UDP_135", "TCP_80", "TCP_89", "TCP_9095", "UDP_16500", "UDP_16501", "UDP_16502", "UDP_16503", "UDP_16504", "UDP_16505", "UDP_16506", "UDP_16507", "UDP_16508", "UDP_16509"]
}

variable "security_group_rule_protocol_adc" {
  type        = list(string)
  description = "ADC protocols"
  default     = ["TCP", "UDP", "TCP", "UDP", "TCP", "UDP", "TCP", "TCP", "TCP", "UDP", "UDP", "TCP", "TCP", "TCP", "UDP", "UDP", "UDP", "UDP", "UDP", "UDP", "UDP", "UDP", "UDP", "UDP"]
}

resource "aws_security_group_rule" "ingress_rules_adc" {
  count             = length(var.security_group_inbound_ports_adc)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_adc[count.index]
  to_port           = var.security_group_inbound_ports_adc[count.index]
  protocol          = var.security_group_rule_protocol_adc[count.index]
  cidr_blocks       = ["${aws_eip.citrix_eip_pub.public_ip}/32"]
  description       = var.security_group_rule_description_adc[count.index]
  security_group_id = aws_security_group.ec2_security_adc.id
}



##############################################################################################

variable "security_group_inbound_ports_rdp" {
  type        = list(number)
  description = "RDP ports"
  default     = [3389]
}
variable "security_group_rule_description_rdp" {
  type        = list(string)
  description = "Remote Desktop Access "
  default     = ["TCP_3398"]
}

variable "security_group_rule_protocol_rdp" {
  type        = list(string)
  description = "RDP Proto"
  default     = ["TCP"]
}

resource "aws_security_group_rule" "ingress_rules_rdp" {
  count             = length(var.security_group_inbound_ports_rdp)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_rdp[count.index]
  to_port           = var.security_group_inbound_ports_rdp[count.index]
  protocol          = var.security_group_rule_protocol_rdp[count.index]
  cidr_blocks       = ["${join(" ", module.win2016_multiple["COR-A-CTX02"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX03"].private_ip)}/32"]
  description       = var.security_group_rule_description_rdp[count.index]
  security_group_id = aws_security_group.ec2_security_rdp.id
}

##############################################################################################

variable "security_group_inbound_ports_sf" {
  type        = list(number)
  description = "SF ports"
  default     = [1433, 9080, 9443, 9501, 443, 1433, 9080, 9443, 9501, 443]
}
variable "security_group_rule_description_sf" {
  type        = list(string)
  description = "SF Access "
  default     = ["TCP_1433", "TCP_9080", "TCP_9443", "TCP_9501", "TCP_443", "UDP_1433", "UDP_9080", "UDP_9443", "UDP_9501", "UDP_443"]
}

variable "security_group_rule_protocol_sf" {
  type        = list(string)
  description = "SF Proto"
  default     = ["TCP", "TCP", "TCP", "TCP", "TCP", "UDP", "UDP", "UDP", "UDP", "UDP"]
}

resource "aws_security_group_rule" "ingress_rules_sf" {
  count             = length(var.security_group_inbound_ports_sf)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_sf[count.index]
  to_port           = var.security_group_inbound_ports_sf[count.index]
  protocol          = var.security_group_rule_protocol_sf[count.index]
  cidr_blocks       = ["${join(" ", module.win2012_SQL_multiple["COR-A-SF02"].private_ip)}/32", "${join(" ", module.win2012_STD_multiple["COR-A-SF01"].private_ip)}/32", "${join(" ", module.win2012_STD_multiple["COR-A-SF03"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX02"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX03"].private_ip)}/32"]
  description       = var.security_group_rule_description_sf[count.index]
  security_group_id = aws_security_group.ec2_security_sf.id
}


##############################################################################################


variable "security_group_inbound_ports_citrix" {
  type        = list(number)
  description = "citrix ports"
  default     = [27000]
}
variable "security_group_rule_description_citrix" {
  type        = list(string)
  description = "citrix Access "
  default     = ["TCP_27000"]
}

variable "security_group_rule_protocol_citrix" {
  type        = list(string)
  description = "Citrix Proto"
  default     = ["TCP"]
}

resource "aws_security_group_rule" "ingress_rules_citrix" {
  count             = length(var.security_group_inbound_ports_citrix)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_citrix[count.index]
  to_port           = var.security_group_inbound_ports_citrix[count.index]
  protocol          = var.security_group_rule_protocol_citrix[count.index]
  cidr_blocks       = ["${join(" ", module.win2016_multiple["COR-A-CTX01"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX02"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX03"].private_ip)}/32"]
  description       = var.security_group_rule_description_citrix[count.index]
  security_group_id = aws_security_group.ec2_security_citrix.id
}

##############################################################################################

variable "security_group_inbound_ports_samba" {
  type        = list(number)
  description = "samba ports"
  default     = [445, 445]
}
variable "security_group_rule_description_samba" {
  type        = list(string)
  description = "samba Access "
  default     = ["TCP_445", "UDP_445"]
}

variable "security_group_rule_protocol_samba" {
  type        = list(string)
  description = "Citrix Proto"
  default     = ["TCP", "UDP"]
}

resource "aws_security_group_rule" "ingress_rules_samba" {
  count             = length(var.security_group_inbound_ports_samba)
  type              = "ingress"
  from_port         = var.security_group_inbound_ports_samba[count.index]
  to_port           = var.security_group_inbound_ports_samba[count.index]
  protocol          = var.security_group_rule_protocol_samba[count.index]
  cidr_blocks       = ["${join(" ", module.win2012_STD_multiple["COR-A-EQP01"].private_ip)}/32", "${join(" ", module.win2012_STD_multiple["COR-A-EQP02"].private_ip)}/32", "${join(" ", module.win2012_STD_multiple["COR-A-EQP03"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX02"].private_ip)}/32", "${join(" ", module.win2016_multiple["COR-A-CTX03"].private_ip)}/32"]
  description       = var.security_group_rule_description_samba[count.index]
  security_group_id = aws_security_group.ec2_security_samba.id
}
