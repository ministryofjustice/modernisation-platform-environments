# ------------------------------------------------------------------------------
# Observability Platform
# Configure tenant access for CloudWatch and the operational Athena datasource.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "observability_platform_athena" {
  statement {
    sid    = "AthenaMetadataAccess"
    effect = "Allow"

    actions = [
      "athena:GetDatabase",
      "athena:GetDataCatalog",
      "athena:GetTableMetadata",
      "athena:ListDatabases",
      "athena:ListDataCatalogs",
      "athena:ListTableMetadata",
      "athena:ListWorkGroups",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AthenaQueryAccess"
    effect = "Allow"

    actions = [
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
    ]

    resources = [aws_athena_workgroup.observability_platform.arn]
  }

  statement {
    sid    = "GlueOpsMonitoringRead"
    effect = "Allow"

    actions = [
      "glue:BatchGetPartition",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
    ]

    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      aws_glue_catalog_database.ops_monitoring.arn,
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/${aws_glue_catalog_database.ops_monitoring.name}/*",
    ]
  }

  statement {
    sid       = "LakeFormationDataAccess"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  statement {
    sid    = "AthenaResultsBucketRead"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [module.s3-athena-bucket.bucket.arn]
  }

  statement {
    sid    = "AthenaResultsObjectAccess"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]

    resources = [
      "${module.s3-athena-bucket.bucket.arn}/output/observability_platform/*",
    ]
  }
}

resource "aws_iam_policy" "observability_platform_athena" {
  name_prefix = "observability-platform-athena-"
  description = "Athena access to operational monitoring data for Grafana"
  policy      = data.aws_iam_policy_document.observability_platform_athena.json
}

module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "2.0.0"

  observability_platform_account_id = (
    local.environment_management.account_ids[
      "observability-platform-production"
    ]
  )

  additional_policies = {
    athena = aws_iam_policy.observability_platform_athena.arn
  }

  tags = local.tags
}

data "aws_iam_role" "observability_platform" {
  name = "observability-platform"

  depends_on = [module.observability_platform_tenant]
}
