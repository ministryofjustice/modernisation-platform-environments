##############################################
### Security Group for User Creation EC2 Instance
##############################################

resource "aws_security_group" "user_creation_ec2_sg" {
  count = local.environment == "development" ? 1 : 0

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
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.user_creation_ec2_sg[0].id
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
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.user_creation_ec2_sg[0].id
  description       = "Allow RDP from private subnets"
  ip_protocol       = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_ipv4         = data.terraform_remote_state.workspace_components.outputs.vpc_cidr

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-rdp" }
  )
}

# Ingress rule - Allow communication with Microsoft AD
resource "aws_vpc_security_group_ingress_rule" "user_creation_ec2_ad" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.user_creation_ec2_sg[0].id
  description       = "Allow communication with Microsoft AD"
  ip_protocol       = "-1"
  cidr_ipv4         = data.terraform_remote_state.workspace_components.outputs.vpc_cidr

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-ad" }
  )
}
