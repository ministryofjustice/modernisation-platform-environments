locals {
  business_unit     = var.networking[0].business-unit
  vpc_name          = var.networking[0].business-unit
  application_name  = var.networking[0].application
  environment       = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  subnet_set        = var.networking[0].set
  provider_name     = "core-vpc-${local.environment}"
  region            = "eu-west-2"
  availability_zone = "eu-west-2a"

  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value
  environment_management            = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  tags                              = module.environment.tags
}

locals {
  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

data "aws_iam_session_context" "whoami" {
  provider = aws.oidc-session
  arn      = data.aws_caller_identity.oidc_session.arn
}