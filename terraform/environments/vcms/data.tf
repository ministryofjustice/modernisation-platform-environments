#### This file can be used to store data specific to the member account ####
data "aws_security_group" "vcms_ecs" {
  name   = "vcms-ecs"
  vpc_id = local.account_info.vpc_id
}