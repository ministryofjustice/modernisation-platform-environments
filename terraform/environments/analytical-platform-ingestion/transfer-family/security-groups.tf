module "transfer_server_security_group" {
  source  = "terraform-aws-modules/security-group/aws.git?ref=badbab67cd0d7f976523fd44647e1ee9fb87001b" # commit hash of version 5.3.0
  version = "5.3.0"

  name        = "transfer-server"
  description = "Security Group for Transfer Server"
  vpc_id      = data.aws_vpc.isolated.id
}

resource "aws_security_group_rule" "this" {
  count = length(local.all_cidr_blocks) > 0 ? 1 : 0

  description       = "Allow inbound SFTP traffic to Transfer Server"
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = local.all_cidr_blocks
  security_group_id = module.transfer_server_security_group.security_group_id
}
