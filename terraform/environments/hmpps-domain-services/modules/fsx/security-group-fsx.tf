#######################################
# SECURITY GROUPS
#  see https://docs.aws.amazon.com/fsx/latest/WindowsGuide/fsx-aws-managed-ad.html
#######################################

resource "aws_security_group" "fsx" {
  name        = "${var.fsx.common_name}-fsx"
  description = "security group for ${var.fsx.common_name}-fsx instances to fsx filesystem"
  vpc_id      = var.common.vpc_id

  tags = merge(
    var.common.tags,
    {
      "Name" = "${var.fsx.common_name}-fsx"
    },
  )

  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "aws_security_group_rule" "fsx_ingress_all_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.fsx.id
  self              = true
  description       = "ingress ALL security group internal traffic"
}

resource "aws_security_group_rule" "fsx_egress_all_internal" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.fsx.id
  self              = true
  description       = "egress ALL security group internal traffic"
}

resource "aws_security_group_rule" "fsx_egress_tcp_53" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.fsx.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "egresss to tcp/53 DNS"
}

resource "aws_security_group_rule" "fsx_egress_udp_53" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.fsx.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "egress to udp/53 DNS"
}

# allow egress to AD Domain Controllers -  TCP 88, 135,389, 445, 464, 636, 3268, 9389, 49152-65535
resource "aws_security_group_rule" "fsx_egress_ad_tcp_88" {
  type                     = "egress"
  from_port                = 88
  to_port                  = 88
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/88 Kerberos authentication"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_135" {
  type                     = "egress"
  from_port                = 135
  to_port                  = 135
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/135 DCE / EPMAP"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_389" {
  type                     = "egress"
  from_port                = 389
  to_port                  = 389
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/389 Lightweight Directory Access Protocol (LDAP)"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_445" {
  type                     = "egress"
  from_port                = 445
  to_port                  = 445
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/445 Directory Services SMB file sharing"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_464" {
  type                     = "egress"
  from_port                = 464
  to_port                  = 464
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/464 Change/Set password"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_636" {
  type                     = "egress"
  from_port                = 636
  to_port                  = 636
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/636 Directory Services SMB file sharing"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_3268" {
  type                     = "egress"
  from_port                = 3268
  to_port                  = 3268
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/3268 Microsoft Global Catalog"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_3269" {
  type                     = "egress"
  from_port                = 3269
  to_port                  = 3269
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/3269 Microsoft Global Catalog over SSL"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_5985" {
  type                     = "egress"
  from_port                = 5985
  to_port                  = 5985
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/5985 WinRM 2.0"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_9389" {
  type                     = "egress"
  from_port                = 9389
  to_port                  = 9389
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/9389 Microsoft AD DS Web Services, PowerShell"
}

resource "aws_security_group_rule" "fsx_egress_ad_tcp_49152_65535" {
  type                     = "egress"
  from_port                = 49152
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress tcp/49152-65535 Ephemeral ports for RPC"
}

# allow egress to AD Domain Controllers -  UDP 88.123.389,464
resource "aws_security_group_rule" "fsx_egress_ad_udp_88" {
  type                     = "egress"
  from_port                = 88
  to_port                  = 88
  protocol                 = "udp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress udp/88 Active Directory Kerberos"
}

resource "aws_security_group_rule" "fsx_egress_ad_udp_123" {
  type                     = "egress"
  from_port                = 123
  to_port                  = 123
  protocol                 = "udp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress udp/123 Active Directory NTP"
}

resource "aws_security_group_rule" "fsx_egress_ad_udp_389" {
  type                     = "egress"
  from_port                = 389
  to_port                  = 389
  protocol                 = "udp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress udp/389 Active Directory LDAP"
}

resource "aws_security_group_rule" "fsx_egress_ad_udp_464" {
  type                     = "egress"
  from_port                = 464
  to_port                  = 464
  protocol                 = "udp"
  security_group_id        = aws_security_group.fsx.id
  source_security_group_id = var.fsx.active_directory_security_group_id
  description              = "egress udp/464 Active Directory"
}

# ============================================
# FSx Security Group
# ============================================
resource "aws_security_group_rule" "fsx_sg_ingress_from_fsx_integration_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx_integration.id
  security_group_id        = aws_security_group.fsx.id
  description              = "ingress ALL traffic from FSx Integration Security Group"
}

resource "aws_security_group_rule" "fsx_sg_ingress_from_ad_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = var.fsx.active_directory_security_group_id
  security_group_id        = aws_security_group.fsx.id
  description              = "ingress ALL traffic from AD Security Group"
}

resource "aws_security_group_rule" "fsx_sg_egress_to_integration_sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx_integration.id
  security_group_id        = aws_security_group.fsx.id
  description              = "egress ALL traffic to FSx Integration Security Group"
}