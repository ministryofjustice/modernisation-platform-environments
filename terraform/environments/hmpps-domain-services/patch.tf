module "test" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v2.0.0"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace]
  application_name = local.application_name
  approval_days    = "0"
  patch_schedule   = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system = "REDHAT_ENTERPRISE_LINUX"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "test-no-suffix-test" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=multiple-schedules"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace]
  application_name = local.application_name
  approval_days    = "0"
  patch_schedule   = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system = "REDHAT_ENTERPRISE_LINUX"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "test-suffix-test" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=multiple-schedules"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace]
  application_name = local.application_name
  approval_days    = "0"
  patch_schedule   = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system = "REDHAT_ENTERPRISE_LINUX"
  suffix           = "-2"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "development" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v2.0.0"
  count  = local.is-development == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace]
  application_name = local.application_name
  approval_days    = "0"
  patch_schedule   = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system = "REDHAT_ENTERPRISE_LINUX"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "preproduction" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v2.0.0"
  count  = local.is-preproduction == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "7"
  patch_schedule       = "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm
  operating_system     = "WINDOWS"
  patch_classification = ["SecurityUpdates", "CriticalUpdates"]
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

# module "production-eu-west-2a" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=multiple-schedules"
#   count  = local.is-production == true ? 1 : 0
#   providers = {
#     aws.bucket-replication = aws
#   }
#
#   account_number       = local.environment_management.account_ids[terraform.workspace]
#   application_name     = local.application_name
#   approval_days        = "14"
#   patch_schedule       = "cron(0 21 ? * THU#3 *)" # 3rd Thurs @ 9pm
#   operating_system     = "WINDOWS"
#   patch_tag            = "eu-west-2a"
#   patch_classification = ["SecurityUpdates", "CriticalUpdates"]
#   suffix               = "-1"
#   tags = merge(
#     local.tags,
#     {
#       Name = "ssm-patching"
#     },
#   )
# }

# module "production-eu-west-2b" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v2.0.0"
#   count  = local.is-production == true ? 1 : 0
#   providers = {
#     aws.bucket-replication = aws
#   }
#
#   account_number       = local.environment_management.account_ids[terraform.workspace]
#   application_name     = local.application_name
#   approval_days        = "14"
#   patch_schedule       = "cron(0 21 ? * THU#4 *)" # 4th Thurs @ 9pm
#   operating_system     = "WINDOWS"
#   patch_tag            = "eu-west-2b"
#   patch_classification = ["SecurityUpdates", "CriticalUpdates"]
#   tags = merge(
#     local.tags,
#     {
#       Name = "ssm-patching"
#     },
#   )
# }
