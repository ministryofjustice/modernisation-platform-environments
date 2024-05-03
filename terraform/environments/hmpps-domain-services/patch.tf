module "test" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v2.0.0"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws.bucket-replication
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