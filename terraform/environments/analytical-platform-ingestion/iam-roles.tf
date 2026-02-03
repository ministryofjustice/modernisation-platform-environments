module "transfer_server_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name            = "transfer-server"
  use_name_prefix = true

  trust_policy_permissions = {
    TransferServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    TransferServerPolicy     = module.transfer_server_iam_policy.arn
    AWSTransferLoggingAccess = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }
}

module "datasync_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name            = "datasync"
  use_name_prefix = true

  trust_policy_permissions = {
    DatasyncServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["datasync.amazonaws.com"]
      }]
    }
  }

  policies = {
    DatasyncPolicy = module.datasync_iam_policy.arn
  }
}

module "datasync_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "datasync-replication"

  trust_policy_permissions = {
    S3ServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    DatasyncReplicationPolicy = module.datasync_replication_iam_policy.arn
  }
}

module "datasync_opg_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "datasync-opg-ingress-${local.environment}-replication"

  trust_policy_permissions = {
    S3ServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    DatasyncOpgReplicationPolicy = module.datasync_opg_replication_iam_policy.arn
  }
}

# Guard Duty Malware Role

module "guard_duty_malware_s3_scan_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "guard-duty-malware-${local.environment}-scan"

  trust_policy_permissions = {
    GuardDutyServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
      }]
    }
  }

  policies = {
    GuardDutyMalwareProtectionPolicy = module.guard_duty_s3_malware_protection_iam_policy.arn
  }
}

module "datasync_laa_data_analysis_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "datasync-laa-data-analysis"

  trust_policy_permissions = {
    DatasyncServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["datasync.amazonaws.com"]
      }]
    }
  }

  policies = {
    LAADataAnalysisPolicy = module.laa_data_analysis_iam_policy[0].arn
  }
}

module "laa_data_analysis_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "laa-data-analysis-${local.environment}-replication"

  trust_policy_permissions = {
    S3ServiceToAssume = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com", "batchoperations.s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    LAADataAnalysisReplicationPolicy = module.laa_data_analysis_replication_iam_policy[0].arn
  }
}
