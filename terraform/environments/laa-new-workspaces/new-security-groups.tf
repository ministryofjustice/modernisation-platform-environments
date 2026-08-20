##############################################
### Security Group for User Creation EC2 Instance
##############################################

resource "aws_security_group" "user_creation_ec2_sg" {

  name_prefix = "${local.application_name}-${local.environment}-user-creation-ec2-sg"
  description = "Security group for user creation EC2 instance"
  vpc_id      = data.terraform_remote_state.workspace_components.outputs.vpc_id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-sg" }
  )
}

# Egress rule - allow all outbound
resource "aws_vpc_security_group_egress_rule" "user_creation_ec2_egress" {

  security_group_id = aws_security_group.user_creation_ec2_sg.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-egress" }
  )
}

# Ingress rule - RDP from private subnets (for troubleshooting via Session Manager)
resource "aws_vpc_security_group_ingress_rule" "user_creation_ec2_rdp" {

  security_group_id = aws_security_group.user_creation_ec2_sg.id
  description       = "Allow RDP from private subnets"
  ip_protocol       = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_ipv4         = data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-rdp" }
  )
}

# Ingress rule - Allow communication with Microsoft AD
resource "aws_vpc_security_group_ingress_rule" "user_creation_ec2_ad" {

  security_group_id = aws_security_group.user_creation_ec2_sg.id
  description       = "Allow communication with Microsoft AD"
  ip_protocol       = "-1"
  cidr_ipv4         = data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-ad" }
  )
}

##############################################
### AD Security Group Rules
### Allow PowerShell AD cmdlets (port 9389)
##############################################

# Allow AD Web Services (ADWS) port 9389 from EC2 to AD
# This is REQUIRED for PowerShell cmdlets like New-ADUser, Get-ADUser, etc.
resource "aws_vpc_security_group_ingress_rule" "ad_adws_from_ec2" {

  security_group_id            = aws_directory_service_directory.workspaces_ad.security_group_id
  description                  = "Allow AD Web Services (ADWS) from user creation EC2"
  ip_protocol                  = "tcp"
  from_port                    = 9389
  to_port                      = 9389
  referenced_security_group_id = aws_security_group.user_creation_ec2_sg.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-adws-from-ec2" }
  )
}
