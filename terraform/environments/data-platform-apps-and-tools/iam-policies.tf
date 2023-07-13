data "aws_iam_policy_document" "airflow_user" {
  statement {
    sid = "AllowAirflowCreateWebLoginToken"
    effect = "Allow"
    actions = ["airflow:CreateWebLoginToken"],
    resources = ["arn:aws:airflow:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:role/${local.airflow_name}/User"]
  }
}

module "airflow_user" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name   = "${local.application_name}-${local.environment}-airflow-user"
  policy = data.aws_iam_policy_document.airflow_user.json

  tags = local.tags
}
