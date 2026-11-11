locals {
  runtime_artifact_prefix = "lambda/dms-runtime-controller/"
}

data "aws_iam_openid_connect_provider" "artifact_publisher" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

data "aws_region" "artifact_publisher" {}

data "aws_iam_policy_document" "artifact_publisher_assume_role" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  statement {
    sid     = "AllowModulesIntegrationBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.artifact_publisher[0].arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:ministryofjustice/terraform-aws-moj-data-factory-modules:ref:refs/heads/integration/data-hub-modularisation"
      ]
    }
  }
}

resource "aws_iam_role" "artifact_publisher" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  name = "${local.application_name}-${local.environment}-artifact-publisher"

  description = "Publish verified ingestion runtime packages from the modules integration branch"

  assume_role_policy = data.aws_iam_policy_document.artifact_publisher_assume_role[0].json

  max_session_duration = 3600

  tags = local.tags
}

data "aws_iam_policy_document" "artifact_publisher" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  statement {
    sid    = "ReadBucketVersioning"
    effect = "Allow"

    actions = ["s3:GetBucketVersioning"]

    resources = [
      aws_s3_bucket.artifacts["packages"].arn
    ]
  }

  statement {
    sid    = "ListRuntimeArtifactPrefix"
    effect = "Allow"

    actions = ["s3:ListBucket"]

    resources = [
      aws_s3_bucket.artifacts["packages"].arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.runtime_artifact_prefix,
        "${local.runtime_artifact_prefix}*",
      ]
    }
  }

  statement {
    sid    = "PublishAndVerifyRuntimeArtifacts"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${aws_s3_bucket.artifacts["packages"].arn}/${local.runtime_artifact_prefix}*"
    ]
  }

  statement {
    sid    = "UseArtifactKeyThroughS3"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.artifacts[0].arn
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.${data.aws_region.artifact_publisher.region}.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role_policy" "artifact_publisher" {
  count = local.ingestion_artifacts_enabled ? 1 : 0

  name   = "publish-dms-runtime-artifacts"
  role   = aws_iam_role.artifact_publisher[0].id
  policy = data.aws_iam_policy_document.artifact_publisher[0].json
}
