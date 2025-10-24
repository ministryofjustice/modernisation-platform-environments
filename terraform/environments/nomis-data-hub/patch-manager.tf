module "patch_manager" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions; this is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v5.1.0"
  providers = {
    aws.bucket-replication = aws
  }
  daily_definition_update = true
  account_number          = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
  application_name        = local.application_name                                        # Required, Name of application, (string) 
  environment             = local.environment
  approval_days = {
    development   = 0
    test          = 6
    preproduction = 10
    production    = 14
  }
  patch_schedules             = local.baseline_environment_specific.patch_manager.patch_schedules
  maintenance_window_cutoff   = local.baseline_environment_specific.patch_manager.maintenance_window_cutoff
  maintenance_window_duration = local.baseline_environment_specific.patch_manager.maintenance_window_duration
  patch_classifications       = local.baseline_environment_specific.patch_manager.patch_classifications
  simple_patching             = true # Optional, Use AWS-RunPatchBaseline directly, instead of AWS-PatchInstanceWithRollback which is a wrapper that adds orchestration and prolific lambda logs.
  tags                        = merge(local.tags, { name = "ssm-patching-module" }, )
}
