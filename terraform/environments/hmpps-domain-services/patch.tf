module "development" {
  count               = local.is-development == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "development"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-development"
  }
  instance_roles = [
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-development}:role/ec2-instance-role-dev-win-2022",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-test}:role/ec2-instance-role-test-win-2022",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-preproduction}:role/ec2-instance-role-pp-rdgw-1-a",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-preproduction}:role/ec2-instance-role-pp-rds-1-a",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-production}:role/ec2-instance-role-pd-rdgw-1-a",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-production}:role/ec2-instance-role-pd-rdgw-1-b",
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-production}:role/ec2-instance-role-pd-rds-1-a"
  ]
}

module "test" {
  count               = local.is-test == true ? 1 : 0
  source              = "../../modules/patch_manager"
  application         = "hmpps-domain-services"
  environment         = "test"
  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
  operating_system    = "WINDOWS"
  schedule            = "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm
  target_tag = {
    "environment-name" = "hmpps-domain-services-test"
  }
  instance_roles = [
    "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-test}:role/ec2-instance-role-test-win-2022",
  ]
}

module "ssm-auto-patching" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v1.0.0"
  count  = local.environment == "development" ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = local.application_name
 approval_days = "7"
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}


#module "preproduction" {
#  count               = local.is-preproduction == true ? 1 : 0
#  source              = "../../modules/patch_manager"
#  application         = "hmpps-domain-services"
#  environment         = "preproduction"
#  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
#  operating_system    = "WINDOWS"
#  schedule            = "cron(0 21 ? * WED#3 *)" # 3rd Weds @ 9pm
#  target_tag = {
#    "environment-name" = "hmpps-domain-services-preproduction"
#  }
#}
#
#module "production" {
#  count               = local.is-production == true ? 1 : 0
#  source              = "../../modules/patch_manager"
#  application         = "hmpps-domain-services"
#  environment         = "production"
#  predefined_baseline = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
#  operating_system    = "WINDOWS"
#  schedule            = "cron(0 21 ? * THU#3 *)" # 3rd Thurs @ 9pm
#  target_tag = {
#    "environment-name" = "hmpps-domain-services-production"
#  }
#}