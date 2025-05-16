# ------------------------------------------
# set up
# ------------------------------------------

locals {
  enable_airflow_secret = local.application_data.accounts[local.environment].enable_airflow_secret
  airflow_secret_placeholder = {
    oidc_cluster_identifier = "placeholder"
  }
  #checkov:skip=CKV_SECRET_6: Ignore this
  airflow_cadt_secret_placeholder = "placeholder"
}
data "aws_secretsmanager_secret" "airflow_secret" {
  name = aws_secretsmanager_secret.airflow_secret[0].id

  depends_on = [aws_secretsmanager_secret_version.airflow_secret]
}

data "aws_secretsmanager_secret_version" "airflow_secret" {
  secret_id = data.aws_secretsmanager_secret.airflow_secret.id

  depends_on = [aws_secretsmanager_secret.airflow_secret]
}


## DBT Analytics EKS Cluster Identifier
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "airflow_secret" {
  count = local.enable_airflow_secret ? 1 : 0

  secret_id     = aws_secretsmanager_secret.airflow_secret[0].id
  secret_string = jsonencode(local.airflow_secret_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.airflow_secret]
}

resource "aws_secretsmanager_secret" "airflow_secret" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  count = local.enable_airflow_secret ? 1 : 0

  name = "external/analytical_platform/airflow_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}


data "tls_certificate" "analytical_platform_compute" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}"
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute" {
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.analytical_platform_compute.certificates[0].sha1_fingerprint]
}

