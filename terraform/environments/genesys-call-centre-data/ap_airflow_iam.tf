data "aws_iam_policy_document" "genesys_ap_airflow" {
  statement {
    sid       = "GenesysAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }
}

module "genesys_ap_airflow" {
  source = "./modules/ap_airflow_iam_role"

  environment         = local.environment
  role_name_suffix    = "genesys-ap-cross-account-access"
  role_description    = ""
  iam_policy_document = data.aws_iam_policy_document.genesys_ap_airflow.json
  secret_code         = jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]
  oidc_arn            = aws_iam_openid_connect_provider.analytical_platform_compute.arn
}
