module "transfer_server_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "transfer-server"

  trust_policy_permissions = {
    AllowTransferService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    transfer_server_policy = module.transfer_server_iam_policy.arn
    aws_transfer_logging   = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }
}

module "datasync_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "datasync"

  trust_policy_permissions = {
    AllowDataSyncService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["datasync.amazonaws.com"]
      }]
    }
  }

  policies = {
    datasync_policy = module.datasync_iam_policy.arn
  }
}

module "datasync_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "datasync-replication"

  trust_policy_permissions = {
    AllowS3Service = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    datasync_replication_policy = module.datasync_replication_iam_policy.arn
  }
}

module "datasync_opg_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "datasync-opg-${local.environment}-replication"

  trust_policy_permissions = {
    AllowS3Service = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    datasync_opg_replication_policy = module.datasync_opg_replication_iam_policy.arn
  }
}

# Guard Duty Malware Role

module "guard_duty_malware_s3_scan_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "guard-duty-malware-${local.environment}-scan"

  trust_policy_permissions = {
    AllowGuardDutyService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
      }]
    }
  }

  policies = {
    guard_duty_malware_protection_policy = module.guard_duty_s3_malware_protection_iam_policy.arn
  }
}

module "datasync_laa_data_analysis_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "datasync-laa-data-analysis"

  trust_policy_permissions = {
    AllowDataSyncService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["datasync.amazonaws.com"]
      }]
    }
  }

  policies = {
    laa_data_analysis_policy = module.laa_data_analysis_iam_policy[0].arn
  }
}

module "laa_data_analysis_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "laa-analysis-${local.environment}-repl"

  trust_policy_permissions = {
    AllowS3Services = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com", "batchoperations.s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    laa_data_analysis_replication_policy = module.laa_data_analysis_replication_iam_policy[0].arn
  }
}
