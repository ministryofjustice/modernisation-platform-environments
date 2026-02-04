module "production_replication_cica_dms_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "cica-dms-ingress-production-replication"

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
    cica_dms_replication_policy = module.production_replication_cica_dms_iam_policy.arn
  }
}

module "tariff_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "tariff-dms-eventbridge-full-load-task-role"

  trust_policy_permissions = {
    AllowSchedulerAndEvents = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = [
          "scheduler.amazonaws.com",
          "apidestinations.events.amazonaws.com"
        ]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values = [
            aws_scheduler_schedule_group.tariff_dms_nightly_full_load.arn,
          ]
        }
      ]
    }
  }

  policies = {
    tariff_eventbridge_dms_policy = module.tariff_eventbridge_dms_full_load_task_policy.arn
  }
}

module "tempus_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name = "tempus-dms-eventbridge-full-load-task-role"

  trust_policy_permissions = {
    AllowSchedulerAndEvents = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = [
          "scheduler.amazonaws.com",
          "apidestinations.events.amazonaws.com"
        ]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceArn"
          values = [
            aws_scheduler_schedule_group.tempus_dms_nightly_full_load.arn
          ]
        }
      ]
    }
  }

  policies = {
    tempus_eventbridge_dms_policy = module.tempus_eventbridge_dms_full_load_task_policy.arn
  }
}
