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
#   approval_days           = "5"                                                           # Optional, Number of days before the package is approved, used by the approval rule only, not required for the automation script, (string)???, 	default 5.
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
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=e6dc50e106ede45ceb17fcf77662ab6a6ba1701e"
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
  # patch_tag_key = "patch-manager" # Optional, defaults as tag:Patching, but can be customised if other tags and values should be used, (string), default	"patch-manager".
  patch_schedules = {
    group1 = "cron(00 10 ? * FRI *)"
    group2 = "cron(00 03 ? * THU *)"
  }
  maintenance_window_cutoff   = 1
  maintenance_window_duration = 2
  patch_classifications = {
    WINDOWS                 = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"]
    REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)	
  }
  tags = merge(local.tags, { name = "ssm-patching-module" }, )
}

# module "patch_manager_redhat" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions; this is an internal module so commit hashes are not needed
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=d4035efe3d10d3b956c6c2cceeefb5a589657f88"
#   providers = {
#     aws.bucket-replication = aws
#   }
#   use_existing_bucket  = true
#   existing_bucket_name = module.patch_manager.s3_report_bucket_name                    # Optional, existing bucket name. If no bucket is provided one will be created.	(string)
#   account_number       = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
#   application_name     = local.application_name                                        # Required, Name of application, (string) 
#   approval_days        = "5"                                                           # Optional, Number of days before the package is approved, used by the approval rule only, not required for the automation script, (string)???, 	default 5.
#   # compliance_level	    # Optional, used by the approval rule only, not required for the automation script, (string), default "CRITICAL"
#   # product	              # Optional, the specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022.	list(string), default	["*"].
              #   severity                    = ["Critical", "Important"] # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].
#   patch_schedules             = local.baseline_preproduction.patch_manager.redhat.patch_schedules
#   maintenance_window_cutoff   = local.baseline_preproduction.patch_manager.redhat.maintenance_window_cutoff
#   maintenance_window_duration = local.baseline_preproduction.patch_manager.redhat.maintenance_window_duration
#   operating_system            = "REDHAT_ENTERPRISE_LINUX" # Optional, used by the approval rule only, not required for the automation script, (string), default "CENTOS".
#   patch_classification        = ["Security", "Bugfix"]    
#   tags                        = merge(local.tags, { name = "ssm-patching-module" }, )
#   depends_on                  = [module.patch_manager]
# }

# module "development" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   # This is an internal module so commit hashes are not needed
#   source               = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
#   count                = local.is-development == true ? 1 : 0
#   providers            = { aws.bucket-replication = aws }
#   account_number       = local.environment_management.account_ids[terraform.workspace]
#   application_name     = local.application_name
#   approval_days        = "0"
#   patch_schedule       = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
#   operating_system     = "REDHAT_ENTERPRISE_LINUX"
#   patch_classification = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)	
#   severity             = ["Critical", "Important"]
#   product              = ["RedhatEnterpriseLinux8.5"]
#   tags                 = merge(local.tags, { Name = "ssm-patching" }, )
# }


# resource "aws_instance" "this" {
#   ami                         = data.aws_ami.this.id
#   associate_public_ip_address = false # create an EIP instead
#   disable_api_termination     = var.instance.disable_api_termination
#   disable_api_stop            = var.instance.disable_api_stop
#   ebs_optimized               = data.aws_ec2_instance_type.this.ebs_optimized_support == "unsupported" ? false : true
#   iam_instance_profile        = aws_iam_instance_profile.this.name
#   instance_type               = var.instance.instance_type
#   key_name                    = var.instance.key_name
#   monitoring                  = coalesce(var.instance.monitoring, true)
#   subnet_id                   = var.subnet_id
#   user_data                   = length(data.cloudinit_config.this) == 0 ? var.user_data_raw : data.cloudinit_config.this[0].rendered
#   vpc_security_group_ids      = var.instance.vpc_security_group_ids

#   metadata_options {
#     #checkov:skip=CKV_AWS_79:This isn't enabled in every environment, so we can't enforce it
#     http_endpoint = coalesce(var.instance.metadata_endpoint_enabled, "enabled")
#     http_tokens   = coalesce(var.instance.metadata_options_http_tokens, "required") #tfsec:ignore:aws-ec2-enforce-http-token-imds
#   }

#   root_block_device {
#     delete_on_termination = true
#     encrypted             = true
#     iops                  = try(local.ebs_volume_root.iops > 0, false) ? local.ebs_volume_root.iops : null
#     kms_key_id            = try(local.ebs_volume_root.kms_key_id, var.ebs_kms_key_id)
#     throughput            = try(local.ebs_volume_root.throughput > 0, false) ? local.ebs_volume_root.throughput : null
#     volume_size           = local.ebs_volume_root.size
#     volume_type           = local.ebs_volume_root.type

#     tags = merge(local.tags, var.ebs_volume_tags, {
#       Name = join("-", [var.name, "root", data.aws_ami.this.root_device_name])
#     })
#   }

#   # block devices specified inline cannot be resized later so remove them here
#   # and define as ebs_volumes later
#   dynamic "ephemeral_block_device" {
#     for_each = try(var.instance.ebs_block_device_inline, false) ? {} : local.ami_block_device_mappings_nonroot
#     content {
#       device_name = ephemeral_block_device.value.device_name
#       no_device   = true
#     }
#   }

#   # only use this inline EBS block if it is easy to recreate the EBS volume
#   # as the block is only used when the EC2 is first created
#   dynamic "ebs_block_device" {
#     for_each = try(var.instance.ebs_block_device_inline, false) ? local.ebs_volumes_nonroot : {}
#     content {
#       device_name = ebs_block_device.key

#       delete_on_termination = true
#       encrypted             = true

#       iops        = try(ebs_block_device.value.iops > 0, false) ? ebs_block_device.value.iops : null
#       kms_key_id  = try(ebs_block_device.value.kms_key_id, var.ebs_kms_key_id)
#       throughput  = try(ebs_block_device.value.throughput > 0, false) ? ebs_block_device.value.throughput : null
#       volume_size = ebs_block_device.value.size
#       volume_type = ebs_block_device.value.type

#       tags = merge(local.tags, var.ebs_volume_tags, {
#         Name = try(
#           join("-", [var.name, ebs_block_device.value.label, ebs_block_device.key]),
#           join("-", [var.name, ebs_block_device.key])
#         )
#       })
#     }
#   }

#   dynamic "private_dns_name_options" {
#     for_each = var.instance.private_dns_name_options != null ? [var.instance.private_dns_name_options] : []
#     content {
#       enable_resource_name_dns_aaaa_record = private_dns_name_options.value.enable_resource_name_dns_aaaa_record
#       enable_resource_name_dns_a_record    = private_dns_name_options.value.enable_resource_name_dns_a_record
#       hostname_type                        = private_dns_name_options.value.hostname_type
#     }
#   }

#   lifecycle {
#     ignore_changes = [
#       user_data,                  # Prevent changes to user_data from destroying existing EC2s
#       ebs_block_device,           # Otherwise EC2 will be refreshed each time
#       associate_public_ip_address # The state erroneously has this set to true after an EC2 is restarted with EIP attached
#     ]
#   }

#   tags = merge(local.tags, var.instance.tags, {
#     Name = var.name
#   })
# }

# variable "instance" {
#   description = "EC2 instance settings, see aws_instance documentation"
#   type = object({
#     associate_public_ip_address  = optional(bool, false)
#     disable_api_termination      = bool
#     disable_api_stop             = bool
#     instance_type                = string
#     key_name                     = string
#     metadata_endpoint_enabled    = optional(string, "enabled")
#     metadata_options_http_tokens = optional(string, "required")
#     monitoring                   = optional(bool, true)
#     ebs_block_device_inline      = optional(bool, false)
#     vpc_security_group_ids       = list(string)
#     private_dns_name_options = optional(object({
#       enable_resource_name_dns_aaaa_record = optional(bool)
#       enable_resource_name_dns_a_record    = optional(bool)
#       hostname_type                        = string
#     }))
#     tags = optional(map(string), {})
#   })
# }
