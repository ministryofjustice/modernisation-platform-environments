#### This file can be used to store data specific to the member account ####
#extract IAM role arn for the modernisation-platform-developer role
data "aws_iam_role" "moj_mp_dev_role" {
  count = local.is-production ? 1 : 0
  name  = local.mp_dev_role
}