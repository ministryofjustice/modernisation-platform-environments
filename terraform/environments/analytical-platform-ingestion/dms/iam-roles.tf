module "production_replication_cica_dms_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "cica-dms-ingress-production-replication"

  trust_policy_permissions = {
    S3ServiceToAssume = {
      actions   = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
    }
  }

  policies = {
    ProductionReplicationPolicy = module.production_replication_cica_dms_iam_policy.arn
  }
}

module "tariff_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "tariff-dms-eventbridge-full-load-task-role"

  trust_policy_permissions = {
    SchedulerServiceToAssume = {
      actions   = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = [
          "scheduler.amazonaws.com",
          "apidestinations.events.amazonaws.com"
        ]
      }]
    }
  }

  trust_policy_conditions = [
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

  policies = {
    TariffEventBridgeDMSPolicy = module.tariff_eventbridge_dms_full_load_task_policy.arn
  }
}

module "tempus_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name = "tempus-dms-eventbridge-full-load-task-role"

  trust_policy_permissions = {
    SchedulerServiceToAssume = {
      actions   = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = [
          "scheduler.amazonaws.com",
          "apidestinations.events.amazonaws.com"
        ]
      }]
    }
  }

  trust_policy_conditions = [
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

  policies = {
    TempusEventBridgeDMSPolicy = module.tempus_eventbridge_dms_full_load_task_policy.arn
  }
}
