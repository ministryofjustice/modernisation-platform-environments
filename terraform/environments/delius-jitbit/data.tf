#### This file can be used to store data specific to the member account ####
data "aws_ssm_parameter" "active_deployment_colour" {
  name = "/delius-jitbit/blue-green-active-colour"
}

data "aws_ssm_parameter" "sandbox_active_deployment_colour" {
  count = local.is-development ? 1 : 0
  name  = "/delius-jitbit/sandbox-blue-green-active-colour"
}