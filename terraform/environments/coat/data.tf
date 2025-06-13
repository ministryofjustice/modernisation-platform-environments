#### This file can be used to store data specific to the member account ####

data "aws_iam_role" "moj_mp_dev_role" {
  count = local.is-production ? 1 : 0
  name  = local.mp_dev_role
}