locals {
  patch_manager = merge(
    local.locals_all_environments.patch_manager,
    lookup(local.locals_environment_specific, "patch_manager", {})
  )
}

module "patch_manager" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions; this is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=PLAT-228-add-approve-until-date-option"
  providers = {
    aws.bucket-replication = aws
  }
  daily_definition_update           = false
  account_number                    = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
  application_name                  = local.application_name                                        # Required, Name of application, (string)
  environment                       = local.environment
  approval_days                     = local.patch_manager.approval_days
  approval_date                     = local.patch_manager.approval_date
  patch_schedules                   = local.patch_manager.patch_schedules
  patch_classifications             = local.patch_manager.patch_classifications
  patch_classifications_cutoff_type = local.patch_manager.patch_classifications_cutoff_type
  patch_tag_key                     = "os-type"
  maintenance_window_duration       = 4
  maintenance_window_cutoff         = 2
  simple_patching                   = true # Optional, Use AWS-RunPatchBaseline directly, instead of AWS-PatchInstanceWithRollback which is a wrapper that adds orchestration and prolific lambda logs.
  tags                              = merge(local.tags, { name = "ssm-patching-module" }, )
}
