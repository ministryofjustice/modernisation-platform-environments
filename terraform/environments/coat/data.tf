#### This file can be used to store data specific to the member account ####

data "aws_iam_role" "moj_mp_dev_role" {
  name = local.mp_dev_role
}