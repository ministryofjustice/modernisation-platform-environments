#create YJSM security group
resource "aws_security_group" "yjsm_service" {
  name        = "YJSM"
  description = "YJSM instance security group"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      "Name" = "yjsm service"
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
  security_group_id = aws_security_group.yjsm_service.id
  description       = "Allow all outbound from ecs"
}


resource "aws_security_group_rule" "ecs_to_yjsm_rule" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
   cidr_blocks             = ["10.0.0.0/16"] # Replace with actual block later
  security_group_id        = aws_security_group.yjsm_service.id
  description              = "ALB to ECS service communication"
}
