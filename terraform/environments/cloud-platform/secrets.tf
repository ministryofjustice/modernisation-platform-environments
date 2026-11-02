#### This file can be used to store secrets specific to the member account ####

# Get the ARN of the environment management secret (held in the Modernisation Platform account)
data "aws_ssm_parameter" "environment_management_arn" {
  count    = terraform.workspace == "cloud-platform-live" ? 1 : 0
  provider = aws.original-session
  name     = "environment_management_arn"
}
