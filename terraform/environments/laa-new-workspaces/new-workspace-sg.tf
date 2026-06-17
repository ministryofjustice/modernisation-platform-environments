##############################################
### Security Group for WorkSpaces
##############################################

resource "aws_security_group" "workspaces" {

  name_prefix = "${local.application_name}-workspaces-"
  description = "Security group for ${local.application_name} WorkSpaces"
  vpc_id      = data.terraform_remote_state.workspace_components.outputs.vpc_id

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

  security_group_id = aws_security_group.workspaces.id
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Ingress - Allow WSP (WorkSpaces Streaming Protocol) from VPC
resource "aws_security_group_rule" "workspaces_wsp_ingress" {

  security_group_id = aws_security_group.workspaces.id
  type              = "ingress"
  description       = "WSP from VPC"
  from_port         = 4195
  to_port           = 4195
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# Ingress - Allow PCoIP from VPC
resource "aws_security_group_rule" "workspaces_pcoip_ingress" {

  security_group_id = aws_security_group.workspaces.id
  type              = "ingress"
  description       = "PCoIP from VPC"
  from_port         = 4172
  to_port           = 4172
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

resource "aws_security_group_rule" "workspaces_pcoip_udp_ingress" {

  security_group_id = aws_security_group.workspaces.id
  type              = "ingress"
  description       = "PCoIP UDP from VPC"
  from_port         = 4172
  to_port           = 4172
  protocol          = "udp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

# Ingress - Allow RDP from VPC (for management)
resource "aws_security_group_rule" "workspaces_rdp_ingress" {

  security_group_id = aws_security_group.workspaces.id
  type              = "ingress"
  description       = "RDP from VPC for management"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
}

