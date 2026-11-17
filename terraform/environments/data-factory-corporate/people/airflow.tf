# Create an empty secret; populate its JSON value manually before enabling.
resource "aws_secretsmanager_secret" "airflow-authentication" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a cluster OIDC identifier; automatic credential rotation is not applicable"
  name        = "external/analytical_platform/airflow_authentication"
  description = "Analytical Platform Compute OIDC cluster identifier for People Airflow workflows"
  kms_key_id  = module.corporate_general_kms_key.key_arn

  tags = local.tags
}

# Read the current secret value only after Airflow access is enabled.
data "aws_secretsmanager_secret_version" "airflow-authentication" {
  count     = local.enable_airflow_iam_role ? 1 : 0
  secret_id = aws_secretsmanager_secret.airflow-authentication.id
}

locals {
  # Use the same cluster identifier for the provider and role trust policy.
  airflow_oidc_cluster_identifier = local.enable_airflow_iam_role ? jsondecode(data.aws_secretsmanager_secret_version.airflow-authentication[0].secret_string)["oidc_cluster_identifier"] : ""
}

# Trust tokens from the Airflow EKS cluster. Reuse or import an existing provider.
resource "aws_iam_openid_connect_provider" "analytical-platform-compute" {
  count = local.enable_airflow_iam_role ? 1 : 0
  url   = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.airflow_oidc_cluster_identifier}"
  # Only accept tokens intended for AWS STS.
  client_id_list = ["sts.amazonaws.com"]
}