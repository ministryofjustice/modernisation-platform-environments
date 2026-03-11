##############################################
### Security Group for WorkSpaces
##############################################

resource "aws_security_group" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-workspaces-"
  description = "Security group for ${local.application_name} WorkSpaces"
  vpc_id      = aws_vpc.workspaces[0].id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-workspaces-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Egress - Allow all outbound traffic
resource "aws_security_group_rule" "workspaces_egress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.workspaces[0].id
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Ingress - Allow WSP (WorkSpaces Streaming Protocol) from VPC
resource "aws_security_group_rule" "workspaces_wsp_ingress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.workspaces[0].id
  type              = "ingress"
  description       = "WSP from VPC"
  from_port         = 4195
  to_port           = 4195
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.workspaces[0].cidr_block]
}

# Ingress - Allow PCoIP from VPC
resource "aws_security_group_rule" "workspaces_pcoip_ingress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.workspaces[0].id
  type              = "ingress"
  description       = "PCoIP from VPC"
  from_port         = 4172
  to_port           = 4172
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.workspaces[0].cidr_block]
}

resource "aws_security_group_rule" "workspaces_pcoip_udp_ingress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.workspaces[0].id
  type              = "ingress"
  description       = "PCoIP UDP from VPC"
  from_port         = 4172
  to_port           = 4172
  protocol          = "udp"
  cidr_blocks       = [aws_vpc.workspaces[0].cidr_block]
}

# Ingress - Allow RDP from VPC (for management)
resource "aws_security_group_rule" "workspaces_rdp_ingress" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.workspaces[0].id
  type              = "ingress"
  description       = "RDP from VPC for management"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.workspaces[0].cidr_block]
}

