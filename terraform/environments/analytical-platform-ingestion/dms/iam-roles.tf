module "production_replication_cica_dms_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "cica-dms-ingress-production-replication"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]

  custom_role_policy_arns = [module.production_replication_cica_dms_iam_policy.arn]
}

module "tariff_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "tariff-dms-eventbridge-full-load-task-role"
  role_requires_mfa = false

  trusted_role_services = [
    "scheduler.amazonaws.com",
    "apidestinations.events.amazonaws.com"
  ]

  custom_role_policy_arns = [module.tariff_eventbridge_dms_full_load_task_policy.arn]
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
}

module "tempus_eventbridge_dms_full_load_task_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "tempus-dms-eventbridge-full-load-task-role"
  role_requires_mfa = false

  trusted_role_services = [
    "scheduler.amazonaws.com",
    "apidestinations.events.amazonaws.com"
  ]

  custom_role_policy_arns = [module.tempus_eventbridge_dms_full_load_task_policy.arn]
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
}
