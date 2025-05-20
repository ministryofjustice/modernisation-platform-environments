module "observability_platform_tenant" {

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=fbbe5c8282786bcc0a00c969fe598e14f12eea9b" # v1.2.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  additional_policies = {
    additional_athena_policy = aws_iam_policy.grafana_athena_full_access_policy.arn
  }

  tags = local.tags
}


resource "aws_iam_policy" "grafana_athena_full_access_policy" {
  name   = "grafana_athena_full_access_policy"
  policy = data.aws_iam_policy_document.grafana_athena_full_access_policy.json
}

data "aws_iam_policy_document" "grafana_athena_full_access_policy" {

  statement {
    effect = "Allow"

    actions = [
      "athena:GetDatabase",
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetTableMetadata",
      "athena:GetWorkGroup",
      "athena:ListDatabases",
      "athena:ListDataCatalogs",
      "athena:ListWorkGroups",
      "athena:ListTableMetadata",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:PutObject",
      "s3:PutBucketPublicAccessBlock"
    ]

    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*"
    ]
  }
}