locals {
  dspm_regions                = ["eu-west-2"]
  enable_dspm                 = true
  enable_realtime_visibility  = true
  enable_sensor_management    = true
  enabled_regions             = ["eu-west-2"]
  primary_region              = "eu-west-2"
  realtime_visibility_regions = ["eu-west-2"]
  resource_prefix             = "marlin-crowdstrike-"
  use_existing_cloudtrail     = true
}

# Provision AWS account in Falcon.
resource "crowdstrike_cloud_aws_account" "this" {
  provider   = crowdstrike
  account_id = local.environment_management.account_ids[terraform.workspace]
  asset_inventory = {
    enabled = true
  }
  dspm = {
    enabled = local.enable_dspm
  }
  idp = {
    enabled = local.enable_realtime_visibility
  }
  realtime_visibility = {
    enabled                 = local.enable_realtime_visibility
    cloudtrail_region       = local.primary_region
    use_existing_cloudtrail = local.use_existing_cloudtrail
  }
  sensor_management = {
    enabled = local.enable_sensor_management
  }
}

module "fcs_account_primary" {
  #checkov:skip=CKV_TF_1: Module registry does not support commit hashes
  depends_on                 = [crowdstrike_cloud_aws_account.this]
  source                     = "CrowdStrike/cloud-registration/aws"
  version                    = "0.1.3"
  falcon_client_id           = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_id
  falcon_client_secret       = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_secret
  account_id                 = local.environment_management.account_ids[terraform.workspace]
  permissions_boundary       = ""
  primary_region             = local.primary_region
  enable_sensor_management   = local.enable_sensor_management
  enable_realtime_visibility = local.enable_realtime_visibility && (contains(local.realtime_visibility_regions, "all") || contains(local.realtime_visibility_regions, "us-east-1"))
  use_existing_cloudtrail    = local.use_existing_cloudtrail
  enable_dspm                = local.enable_dspm
  dspm_regions               = local.dspm_regions

  iam_role_name          = crowdstrike_cloud_aws_account.this.iam_role_name
  external_id            = crowdstrike_cloud_aws_account.this.external_id
  intermediate_role_arn  = crowdstrike_cloud_aws_account.this.intermediate_role_arn
  eventbus_arn           = crowdstrike_cloud_aws_account.this.eventbus_arn
  dspm_role_name         = crowdstrike_cloud_aws_account.this.dspm_role_name
  cloudtrail_bucket_name = crowdstrike_cloud_aws_account.this.cloudtrail_bucket_name

  resource_prefix = local.resource_prefix
  resource_suffix = ""
  tags            = local.tags

  providers = {
    aws         = aws.us-east-1
    crowdstrike = crowdstrike
  }
}

module "fcs_account_eu_west_2" {
  #checkov:skip=CKV_TF_1: Module registry does not support commit hashes
  depends_on = [crowdstrike_cloud_aws_account.this, module.fcs_account_primary]
  providers = {
    aws         = aws
    crowdstrike = crowdstrike
  }
  source                     = "CrowdStrike/cloud-registration/aws"
  version                    = "0.1.3"
  falcon_client_id           = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_id
  falcon_client_secret       = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_secret
  account_id                 = local.environment_management.account_ids[terraform.workspace]
  permissions_boundary       = ""
  primary_region             = "eu-west-2"
  enable_sensor_management   = local.enable_sensor_management
  enable_realtime_visibility = local.enable_realtime_visibility && (contains(local.realtime_visibility_regions, "all") || contains(local.realtime_visibility_regions, "eu-west-2"))
  use_existing_cloudtrail    = local.use_existing_cloudtrail
  enable_dspm                = local.enable_dspm
  dspm_regions               = local.dspm_regions

  iam_role_name                   = crowdstrike_cloud_aws_account.this.iam_role_name
  external_id                     = crowdstrike_cloud_aws_account.this.external_id
  intermediate_role_arn           = crowdstrike_cloud_aws_account.this.intermediate_role_arn
  eventbus_arn                    = crowdstrike_cloud_aws_account.this.eventbus_arn
  dspm_role_name                  = crowdstrike_cloud_aws_account.this.dspm_role_name
  cloudtrail_bucket_name          = crowdstrike_cloud_aws_account.this.cloudtrail_bucket_name
  dspm_integration_role_unique_id = module.fcs_account_primary.integration_role_unique_id
  dspm_scanner_role_unique_id     = module.fcs_account_primary.scanner_role_unique_id

  resource_prefix = local.resource_prefix
  resource_suffix = ""
  tags            = local.tags
}