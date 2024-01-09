######################################
# Security Groups
######################################

resource "aws_security_group" "maat_api_ecs_security_group" {
  name        = "${local.application_name}-api-ecs-sg"
  description = "MAAT API ECS Security Group"
  vpc_id      = data.aws_vpc.shared.id 
}

resource "aws_security_group" "maat_api_alb_sg" {
  name        = "${local.application_name}-api-alb-sg"
  description = "MAAT API ALB Security Group"
  vpc_id      = data.aws_vpc.shared.id 
}

resource "aws_security_group" "maat_api_gw_sg" {
  name        = "${local.application_name}-api-gw-sg"
  description = "MAAT API GW Security Group"
  vpc_id      = data.aws_vpc.shared.id 
}

######################################
# Security Group Rules
######################################

resource "aws_security_group_rule" "AppEcsSecurityGroup1ALBport" {
  type              = "ingress"
  from_port         = 8090
  to_port           = 8090
  protocol          = "tcp"
  security_group_id = aws_security_group.maat_api_ecs_security_group.id
  source_security_group_id = aws_security_group.maat_api_alb_sg.id
}

resource "aws_security_group_rule" "AppAlbSecurityGroupApiGatewayIngress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.maat_api_alb_sg.id
  source_security_group_id = aws_security_group.maat_api_gw_sg.id
}

resource "aws_security_group_rule" "AppAlbSecurityGroupModPlatformIngress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.maat_api_alb_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].mlra_vpc_cidr]
}


# ######################################
# # Amend this resounce creation to allow ingress rule for MAAT API ALB Security Group from MLRA Application Security Group
# ######################################
# resource "aws_security_group_rule" "AppAlbSecurityGroupMlraAppInbound" {
#   count             = var.cAddMlraAppSecurityGroupId ? 1 : 0
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   security_group_id = aws_security_group.AppAlbSecurityGroup.id
#   source_security_group_id = var.pMlraAppSecurityGroupId
# }

