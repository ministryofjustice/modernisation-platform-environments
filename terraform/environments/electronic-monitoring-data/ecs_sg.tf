resource "aws_security_group" "ecs_generic" {
  name_prefix = "${local.bucket_prefix}-generic-ecs-sg"
  description = "Generic ECS Security Group"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecs_egress_ecr" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_generic.id

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  description = "Allow HTTPS outbound for ECR and CloudWatch logs"
}
