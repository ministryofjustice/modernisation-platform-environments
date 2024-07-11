module "test-2a" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=ssm-patch-module-refactor"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number      = local.environment_management.account_ids[terraform.workspace]
  application_name    = local.application_name
  approval_days       = "0"
  patch_schedule      = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system    = "WINDOWS"
  suffix               = "-win"
  patch_tag           = "eu-west-2a"
  patch_classification = ["SecurityUpdates", "CriticalUpdates"]
  severity            = ["Critical","Important"]
  product             = ["WindowsServer2022"]


  tags = merge(
    local.tags,
    {
      Name = "ssm-patching-win"
    },
  )
}

module "test-2c" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=ssm-patch-module-refactor"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number      = local.environment_management.account_ids[terraform.workspace]
  application_name    = local.application_name
  approval_days       = "0"
  patch_schedule      = "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm
  operating_system    = "REDHAT_ENTERPRISE_LINUX"
  suffix               = "-red"
  patch_tag           = "eu-west-2c"
  patch_classification = ["Security", "Bugfix"]
  severity            = ["Critical","Important"]
  product             = ["RedhatEnterpriseLinux8.5"]


  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.0.0"

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
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.0.0"
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

module "production-eu-west-2a" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.0.0"
  count  = local.is-production == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "14"
  patch_schedule       = "cron(0 21 ? * THU#3 *)" # 3rd Thurs @ 9pm
  operating_system     = "WINDOWS"
  patch_tag            = "eu-west-2a"
  suffix               = "-2a"
  patch_classification = ["SecurityUpdates", "CriticalUpdates"]
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "production-eu-west-2b" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.0.0"
  count  = local.is-production == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "14"
  patch_schedule       = "cron(0 21 ? * THU#4 *)" # 4th Thurs @ 9pm
  operating_system     = "WINDOWS"
  patch_tag            = "eu-west-2b"
  suffix               = "-2b"
  patch_classification = ["SecurityUpdates", "CriticalUpdates"]
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}
