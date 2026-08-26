
data "aws_iam_policy_document" "datahub_read_cadet_bucket" {
  statement {
    sid    = "datahubReadCaDeTBucket"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Describe*"
    ]
    resources = [
      "${module.s3_structured_historical_bucket.bucket_arn}/data/prod/run_artefacts/*",
      "${module.s3_structured_historical_bucket.bucket_arn}/data/preprod/run_artefacts/*",
      module.s3_structured_historical_bucket.bucket_arn
    ]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      local.s3_kms_arn
    ]
  }
}

resource "aws_iam_policy" "datahub_read_cadet_bucket" {
  name   = "${local.project}_datahub_read_cadet_bucket"
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
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
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
  name                 = "${local.project}_datahub-ingestion-github-actions"
  assume_role_policy   = data.aws_iam_policy_document.datahub_ingestion_github_actions.json
  max_session_duration = 14400

  tags = merge(
    local.tags,
    {
      dpr-name           = "${local.project}_datahub-ingestion-github-actions"
      dpr-resource-type  = "iam"
      dpr-jira           = "DPR2-751"
      dpr-resource-group = "Front-End"
    }
  )
}

resource "aws_iam_role_policy_attachment" "datahub_ingestion_github_actions" {
  policy_arn = aws_iam_policy.datahub_read_cadet_bucket.arn
  role       = aws_iam_role.datahub_ingestion_github_actions.name
}
