
locals {
  datahub_cp_irsa_role_names = {
    dev     = "cloud-platform-irsa-33e75989394c3a08-live",
    test    = "cloud-platform-irsa-fdce67955f41b322-live",
    preprod = "cloud-platform-irsa-fe098636951cc219-live"
  }

  account_ids = {
    cloud-platform = "754256621582"
  }

  datahub_cp_irsa_role_arns = {
    for env, role_name in local.datahub_cp_irsa_role_names :
    env => "arn:aws:iam::${local.account_ids["cloud-platform"]}:role/${role_name}"
  }
}

data "aws_iam_policy_document" "datahub_read_cadet_bucket" {
  statement {
    sid    = "datahubReadCaDeTBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:DescribeJob",
      "s3:DescribeMultiRegionAccessPointOperation"
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/em_data_artefacts/*",
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
}

resource "aws_iam_policy" "datahub_read_cadet_bucket" {
  name   = "datahub_read_CaDeT_bucket"
  policy = data.aws_iam_policy_document.datahub_read_cadet_bucket.json
}

# Allow Github actions to assume a role via OIDC.
# So that scheduled jobs in the data-catalogue repo can access the CaDeT bucket.
data "aws_iam_policy_document" "datahub_ingestion_github_actions" {
  # checkov:skip=CKV_AWS_358: Bug in the linter
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.env_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/data-catalogue:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role" "datahub_ingestion_github_actions" {
  name                 = "datahub-ingestion-github-actions"
  assume_role_policy   = data.aws_iam_policy_document.datahub_ingestion_github_actions.json
  max_session_duration = 14400
}

resource "aws_iam_role_policy_attachment" "datahub_ingestion_github_actions" {
  policy_arn = aws_iam_policy.datahub_read_cadet_bucket.arn
  role       = aws_iam_role.datahub_ingestion_github_actions.name
}
