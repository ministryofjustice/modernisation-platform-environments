#### This file can be used to store data specific to the member account ####
data "aws_ssm_parameter" "active_deployment_colour" {
  name = "/delius-jitbit/blue-green-active-colour"
}