# resource "aws_ssm_maintenance_window" "ssm-maintenance-window" {
#   for_each = {for patch_schedule in var.patch_schedules : patch_schedule.name => patch_schedule}
#   name     = each.value.name # "${var.application_name}-maintenance-window${var.suffix}"
#   schedule = var.patch_schedule # (Required) The schedule of the Maintenance Window in the form of a cron or rate expression.
#   duration = each.value.duration # 4 # (Required) The duration of the Maintenance Window in hours.
#   cutoff   = each.value.cutoff # 3 # (Required) The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution.
# }

#   environment_variables = {
#     ENVIRONMENT_NAME = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"
#   }

# for_each = var.patch_schedules != null ? {this = var.patch_schedules } : []

# variable "patch_schedules" {
#   default = "cron(0 16 ? * TUE *)"
#   description = "List of the schedules...(Required) The schedule of the Maintenance Window in the form of a cron or rate expression."
#   type = string
# }

# locals {
#   outer_list = ["a", "b"]
#   inner_map = {
#     a = ["1", "2"]
#     b = ["3", "4"]
#   }
# }

# resource "example_resource" "example" {
#   for_each = toset(local.outer_list)

#   name = each.key

#   dynamic "inner" {
#     for_each = local.inner_map[each.key]
#     content {
#       value = inner.value
#     }
#   }
# }

# locals {
#   create_bucket = var.existing_bucket_name == "" ? { "bucket" = true } : {}
# }
# resource "aws_s3_bucket" "example" {
#   for_each = local.create_bucket
#   bucket = each.key
#   # other bucket configurations
# }

# module "patch_manager" {
#   for_each = local.baseline_preproduction.patch_manager
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions; this is an internal module so commit hashes are not needed
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=d4035efe3d10d3b956c6c2cceeefb5a589657f88"
#   # count  = local.is-preproduction == true ? 1 : 0
#   # for_each = toset(local.patch_schedules) #   for_each = var.ec2_instances # typically this is where our 'for_each loop would be, but we don't want a full set of resources for every schedule, so their is a for_each in the module

#   providers = {
#     aws.bucket-replication = aws
#   }
#   use_existing_bucket     = true
#   existing_bucket_name    = "davetest" # Optional, existing bucket name. If no bucket is provided one will be created for reports.	(string)
#   daily_definition_update = false
#   account_number          = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
#   application_name        = local.application_name                                        # Required, Name of application, (string) 
#   # compliance_level	    # Optional, used by the approval rule only, not required for the automation script, (string), default "CRITICAL"
#   # force_destroy_bucket	# Optional, boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error, default false
#   # product	              # Optional, the specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022.	list(string), default	["*"].
#   # rejected_patches	    # Optional, list of patches to be rejected, type list(string), default [].
#   # severity	            # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].
#   # patch_tag_key = "patch-manager" # Optional, defaults as tag:Patching, but can be customised if other tags and values should be used, (string), default	"patch-manager".
#   patch_schedules             = each.value.patch_schedules
#   maintenance_window_cutoff   = each.value.maintenance_window_cutoff
#   maintenance_window_duration = each.value.maintenance_window_duration
#   operating_system            = each.value.operating_system     //"WINDOWS" # Optional, used by the approval rule only, not required for the automation script, (string), default "CENTOS".
#   patch_classification        = each.value.patch_classification //["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"] # CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades.  Default ["*"]
#   tags                        = merge(local.tags, { name = "ssm-patching-module" }, )
# }

module "patch_manager" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions; this is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=6c791d630f287c03143ca872808af340b372fbd6"
  providers = {
    aws.bucket-replication = aws
  }
  daily_definition_update = true
  account_number          = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
  application_name        = local.application_name                                        # Required, Name of application, (string) 
  environment             = local.environment
  approval_days = {
    development   = 0
    test          = 3
    preproduction = 5
    production    = 7
  }
  # compliance_level	    # Optional, used by the approval rule only, not required for the automation script, (string), default "CRITICAL"
  # force_destroy_bucket	# Optional, boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error, default false
  # product	              # Optional, the specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022.	list(string), default	["*"].
  # rejected_patches	    # Optional, list of patches to be rejected, type list(string), default [].
  # severity	            # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].
  # patch_tag_key = "patch-manager" # Optional, defaults as tag:patch-manager, but can be customised other tag key name should be used.
  patch_schedules             = local.baseline_preproduction.patch_manager.patch_schedules
  maintenance_window_cutoff   = local.baseline_preproduction.patch_manager.maintenance_window_cutoff
  maintenance_window_duration = local.baseline_preproduction.patch_manager.maintenance_window_duration
  patch_classifications       = local.baseline_preproduction.patch_manager.patch_classifications
  tags                        = merge(local.tags, { name = "ssm-patching-module" }, )
}

# module "patch_manager_redhat" {
#   severity                    = ["Critical", "Important"] # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].
# }

