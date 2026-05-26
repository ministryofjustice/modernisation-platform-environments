##############################################
### Security Group for Active Directory
##############################################

resource "aws_security_group" "ad" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-ad-"
  description = "Security group for ${local.application_name} Active Directory"
  vpc_id      = data.terraform_remote_state.workspace_components.outputs.vpc_id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# AD - Allow DNS (TCP)
resource "aws_security_group_rule" "ad_dns_tcp" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "DNS TCP from VPC"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow DNS (UDP)
resource "aws_security_group_rule" "ad_dns_udp" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "DNS UDP from VPC"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow LDAP (TCP)
resource "aws_security_group_rule" "ad_ldap_tcp" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "LDAP TCP from VPC"
  from_port         = 389
  to_port           = 389
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow LDAPS
resource "aws_security_group_rule" "ad_ldaps" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "LDAPS from VPC"
  from_port         = 636
  to_port           = 636
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow Kerberos (TCP)
resource "aws_security_group_rule" "ad_kerberos_tcp" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "Kerberos TCP from VPC"
  from_port         = 88
  to_port           = 88
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow Kerberos (UDP)
resource "aws_security_group_rule" "ad_kerberos_udp" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "Kerberos UDP from VPC"
  from_port         = 88
  to_port           = 88
  protocol          = "udp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow SMB
resource "aws_security_group_rule" "ad_smb" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "ingress"
  description       = "SMB from VPC"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# AD - Allow all outbound
resource "aws_security_group_rule" "ad_egress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.ad[0].id
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}