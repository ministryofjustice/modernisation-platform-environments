#create esb security group
resource "aws_security_group" "esb_service" {
  name        = "esb"
  description = "esb instance security group"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Name" = "esb service"
    },
    local.all_tags,
  )
}

resource "aws_security_group_rule" "allow_all_internal_group" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.esb_service.id
  description       = "Allow all outbound from ecs"
}

# YJSM
resource "aws_security_group_rule" "yjsm_8090" {
  type                     = "ingress"
  from_port                = 8090
  to_port                  = 8090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.esb_service.id
  source_security_group_id = var.yjsm_service_sg_id
  description              = "ESB Hub Page from YJSM Instance"
}

# YJSM
resource "aws_security_group_rule" "yjsm_8092" {
  type                     = "ingress"
  from_port                = 8092
  to_port                  = 8092
  protocol                 = "tcp"
  security_group_id        = aws_security_group.esb_service.id
  source_security_group_id = var.yjsm_service_sg_id
  description              = "ESB Mule 2 from YJSM"
}

#Used for accessing ESB from Tableau is ssm goes down
resource "aws_security_group_rule" "tableau_to_esb_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.esb_service.id
  source_security_group_id = var.tableau_sg_id
  description              = "tableau to esb ssh"
}

# Mgmt server access to ESB
resource "aws_security_group_rule" "mgmt_to_esb_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.esb_service.id
  source_security_group_id = var.mgmt_instance_sg_id
  description              = "management instance to esb ssh"
}

#ESB to ECS
resource "aws_security_group_rule" "esb_to_ecs_int_rule" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.ecs_service_internal_sg_id
  source_security_group_id = aws_security_group.esb_service.id
  description              = "ESB to ECS int communication"
}

#ESB to Int load balancer
resource "aws_security_group_rule" "allow_alb_from_esb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.alb_security_group_id
  source_security_group_id = aws_security_group.esb_service.id
  description              = "ESB to YJAF Internal ALB"
}