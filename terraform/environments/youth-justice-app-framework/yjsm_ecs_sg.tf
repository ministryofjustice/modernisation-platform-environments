# Attached to the yjsm services that call out to the Juniper account over
# Transit Gateway (yjsm-hub dispatching messages, yjsm-hubadmin polling and
# pushing config to the systems). Deliberately has no rules of its own: it is an
# identity for the Juniper side to allow in its own security groups, kept
# separate from common_ecs_service_internal so that allowing it doesn't also
# let every other internal ECS service through. Egress is already open on the
# shared ECS service security group.
resource "aws_security_group" "yjsm_ecs_sg" {
  name        = "yjsm-ecs-sg"
  description = "Identity for yjsm services that call out to Juniper over Transit Gateway"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, { Name = "yjsm-ecs-sg" })
}
