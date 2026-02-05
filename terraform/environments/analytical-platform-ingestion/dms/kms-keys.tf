module "s3_cica_dms_ingress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/cica-dms-ingress"]
  description           = "Used in the CICA DMS Ingress Solution"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "cica_dms_credentials_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["dms/cica-source-credentials"]
  description           = "Used in the CICA DMS Solution to encode secrets"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    tariff_dms_source = {
      grantee_principal = module.cica_dms_tariff_dms_implementation.dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    tempus_dms_casework_source = {
      grantee_principal = module.cica_dms_tempus_dms_implementation["CaseWork"].dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    tempus_dms_sppfinishedjobs_source = {
      grantee_principal = module.cica_dms_tempus_dms_implementation["SPPFinishedJobs"].dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    tempus_dms_sppprocessplatform_source = {
      grantee_principal = module.cica_dms_tempus_dms_implementation["SPPProcessPlatform"].dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = local.tags
}

module "cica_dms_eventscheduler_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["dms/cica-eventscheduler"]
  description           = "Used in the CICA DMS Solution EventScheduler to encode EventBridge Scheduler"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    tariff_dms_source = {
      grantee_principal = module.tariff_eventbridge_dms_full_load_task_role.iam_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
    tempus_dms_source = {
      grantee_principal = module.tempus_eventbridge_dms_full_load_task_role.iam_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = local.tags
}
