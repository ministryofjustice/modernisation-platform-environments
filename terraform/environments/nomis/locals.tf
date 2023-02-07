locals {
  # provider locals (don't change)
  environment                       = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value
  environment_management            = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  business_unit       = var.networking[0].business-unit
  vpc_name            = var.networking[0].business-unit
  application_name    = var.networking[0].application
  subnet_set          = var.networking[0].set
  provider_name       = "core-vpc-${local.environment}"
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"
  tags                = module.environment.tags
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

