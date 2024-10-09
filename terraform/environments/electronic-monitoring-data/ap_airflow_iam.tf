# --------------------------------------------
# oidc assume role policy for airflow
# --------------------------------------------

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.analytical_platform_compute.arn]
    }
    condition {
      values   = ["system:serviceaccount:actions-runner-mojas-airflow"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}::sub"
      test     = "StringLike"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}:aud"
    }
  }
}


# --------------------------------------------
# test airflow iam works
# --------------------------------------------

resource "aws_iam_role" "test_ap_airflow" {
  name                  = "airflow-dev-test-cross-account-access"
  description           = "testing that the oidc conn with ap airflow compute works"
  assume_role_policy    = data.aws_iam_policy_document.oidc_assume_role_policy.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "test_ap_airflow" {
  statement {
    sid       = "TestAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBuckets", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_policy" "test_ap_airflow" {
  name   = "test-ap-airflow-list-buckets"
  policy = data.aws_iam_policy_document.test_ap_airflow.json
}

resource "aws_iam_role_policy_attachment" "test_ap_airflow" {
  role       = aws_iam_role.test_ap_airflow.name
  policy_arn = aws_iam_policy.test_ap_airflow.arn
}
