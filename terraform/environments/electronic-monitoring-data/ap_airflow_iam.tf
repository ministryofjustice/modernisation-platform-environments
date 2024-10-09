data "aws_iam_policy_document" "test_ap_airflow" {
  statement {
    sid       = "TestAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBuckets", "s3:GetBucketLocation", "s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }
}

module "test_ap_airflow" {
  source              = "./modules/ap_airflow_iam_role"
  role_name_suffix    = "test-cross-account-access"
  role_description    = ""
  iam_policy_document = data.aws_iam_policy_document.test_ap_airflow.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
}
