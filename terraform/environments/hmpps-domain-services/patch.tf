module "test-2a" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "0"
  patch_schedule       = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system     = "WINDOWS"
  suffix               = "-win"
  patch_tag            = "eu-west-2a"
  patch_classification = ["SecurityUpdates", "CriticalUpdates"]
  severity             = ["Critical", "Important"]
  product              = ["WindowsServer2022"]


  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "test-2c" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
  count  = local.is-test == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "0"
  patch_schedule       = "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm
  operating_system     = "REDHAT_ENTERPRISE_LINUX"
  suffix               = "-red"
  patch_tag            = "eu-west-2c"
  patch_classification = ["Security", "Bugfix"]
  severity             = ["Critical", "Important"]
  product              = ["RedhatEnterpriseLinux8.5"]


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
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
  count  = local.is-development == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number       = local.environment_management.account_ids[terraform.workspace]
  application_name     = local.application_name
  approval_days        = "0"
  patch_schedule       = "cron(0 21 ? * TUE#2 *)" # 2nd Tues @ 9pm
  operating_system     = "REDHAT_ENTERPRISE_LINUX"
  patch_classification = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)	
  severity             = ["Critical", "Important"]
  product              = ["RedhatEnterpriseLinux8.5"]

  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "preproduction_patchgroup1" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
  count  = local.is-preproduction == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
  application_name = local.application_name                                        # Required, Name of application, (string) 
  approval_days    = "7"                                                           # Optional, Number of days before the package is approved, used by the approval rule only, not required for the automation script, (string)???, 	default "7".
  # compliance_level	    # Optional, used by the approval rule only, not required for the automation script, (string), default "CRITICAL"
  # existing_bucket_name	# Optional, existing bucket name. If no bucket is provided one will be created for them.	(string)
  # force_destroy_bucket	# Optional, boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error, default false
  # product	              # Optional, the specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022.	list(string), default	["*"].
  # rejected_patches	    # Optional, list of patches to be rejected, type list(string), default [].
  # severity	            # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].

  patch_key = "update-ssm-agent" # Optional, defaults as tag:Patching, but can be customised if other tags and values should be used, (string), default	"Patching".
  patch_tag = "patchgroup1"      # Optional, defaults as yes, but can be customised if other tags and values should to be used	(string), default	"Yes".
  suffix    = "-patchgroup1"     # Optional, when creating multiple patch schedules per environment a suffix should be used to differentiate the resultant resource name, type (string), default	"".

  patch_schedule       = "cron(00 03 ? * WED *)"                                     # "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm # optional, crontab on when to run the automation script.	(string), default	"cron(00 22 ? * MON *)".
  operating_system     = "WINDOWS"                                                   # Optional, used by the approval rule only, not required for the automation script, (string), default "CENTOS".
  patch_classification = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"] # CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades.  Default ["*"]
  tags = merge(
    local.tags,
    {
      Name = "ssm-patching"
    },
  )
}

module "preproduction_patchgroup2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v3.1.0"
  count  = local.is-preproduction == true ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number   = local.environment_management.account_ids[terraform.workspace] # Required, Account number of current environment, (string)
  application_name = local.application_name                                        # Required, Name of application, (string) 
  approval_days    = "7"                                                           # Optional, Number of days before the package is approved, used by the approval rule only, not required for the automation script, (string)???, 	default "7".
  # compliance_level	    # Optional, used by the approval rule only, not required for the automation script, (string), default "CRITICAL"
  # existing_bucket_name	# Optional, existing bucket name. If no bucket is provided one will be created for them.	(string)
  # force_destroy_bucket	# Optional, boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error, default false
  # product	              # Optional, the specific product the patch is applicable for e.g. RedhatEnterpriseLinux8.5, WindowsServer2022.	list(string), default	["*"].
  # rejected_patches	    # Optional, list of patches to be rejected, type list(string), default [].
  # severity	            # Optional, severity of the patch e.g. Critical, Important, Medium, Low.  Type list(string),	default ["*"].

  patch_key = "update-ssm-agent" # Optional, defaults as tag:Patching, but can be customised if other tags and values should be used, (string), default	"Patching".
  patch_tag = "patchgroup2"      # Optional, defaults as yes, but can be customised if other tags and values should to be used	(string), default	"Yes".
  suffix    = "-patchgroup2"     # Optional, when creating multiple patch schedules per environment a suffix should be used to differentiate the resultant resource name, type (string), default	"".

  patch_schedule       = "cron(00 03 ? * THU *)"                                     # "cron(0 21 ? * WED#2 *)" # 2nd Weds @ 9pm # optional, crontab on when to run the automation script.	(string), default	"cron(00 22 ? * MON *)".
  operating_system     = "WINDOWS"                                                   # Optional, used by the approval rule only, not required for the automation script, (string), default "CENTOS".
  patch_classification = ["SecurityUpdates", "CriticalUpdates", "DefinitionUpdates"] # CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades.  Default ["*"]
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
