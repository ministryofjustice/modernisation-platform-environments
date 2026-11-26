locals {
  airflow_pda_enabled = contains(["development", "test"], local.environment)

  # Condition-key prefix derived from the provider ARN, e.g. oidc.eks.eu-west-2.amazonaws.com/id/<id>
  airflow_pda_oidc_issuer = element(split("oidc-provider/", module.airflow_oidc.oidc_arn), 1)

  airflow_pda_glue_arn_prefix = "arn:aws:glue:${local.current_account_region}:${local.current_account_id}"
}

data "aws_iam_policy_document" "airflow_pda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.airflow_oidc.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.airflow_pda_oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.airflow_pda_oidc_issuer}:sub"
      values   = ["system:serviceaccount:mwaa:laa-df-pda"]
    }
  }
}

resource "aws_iam_role" "airflow_pda" {
  count = local.airflow_pda_enabled ? 1 : 0

  name               = "airflow_pda"
  assume_role_policy = data.aws_iam_policy_document.airflow_pda_trust.json

  tags = local.tags
}

data "aws_iam_policy_document" "airflow_pda_permissions" {
  statement {
    sid    = "AthenaQueryExecution"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:GetWorkGroup",
    ]
    resources = [aws_athena_workgroup.laa.arn]
  }

  # The laa workgroup writes query results to S3 using the caller's credentials
  statement {
    sid       = "AthenaQueryResultsBucket"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [module.data_lake_buckets["aws-athena-query-results"].bucket.arn]
  }

  statement {
    sid    = "AthenaQueryResultsObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${module.data_lake_buckets["aws-athena-query-results"].bucket.arn}/athena-results/*"]
  }

  statement {
    sid    = "GlueReadMetadata"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
    ]
    resources = [
      "${local.airflow_pda_glue_arn_prefix}:catalog",
      "${local.airflow_pda_glue_arn_prefix}:database/*",
      "${local.airflow_pda_glue_arn_prefix}:table/*/*",
    ]
  }

  # Athena INSERT into an Iceberg table commits by updating the table's metadata location in Glue
  statement {
    sid     = "GlueCommitIcebergDestination"
    effect  = "Allow"
    actions = ["glue:UpdateTable"]
    resources = [
      "${local.airflow_pda_glue_arn_prefix}:catalog",
      "${local.airflow_pda_glue_arn_prefix}:database/*",
      "${local.airflow_pda_glue_arn_prefix}:table/*/*",
    ]
  }

  statement {
    #checkov:skip=CKV_AWS_356: lakeformation:GetDataAccess does not support resource-level permissions
    #checkov:skip=CKV_AWS_111: lakeformation:GetDataAccess does not support resource-level permissions
    sid       = "LakeFormationDataAccess"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  # Data lake key encrypts the Glue Data Catalog and Athena query results
  statement {
    sid       = "DataLakeKmsKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.data_lake_kms_key.arn]
  }
}

resource "aws_iam_role_policy" "airflow_pda_permissions" {
  count = local.airflow_pda_enabled ? 1 : 0

  name   = "airflow-pda-permissions"
  role   = aws_iam_role.airflow_pda[0].id
  policy = data.aws_iam_policy_document.airflow_pda_permissions.json
}

resource "aws_lakeformation_permissions" "airflow_pda_source_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = "data_claims"
  }
}

resource "aws_lakeformation_permissions" "airflow_pda_source_table" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "data_claims"
    name          = "submission"
  }
}

resource "aws_lakeformation_permissions" "airflow_pda_destination_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = "pda-raw"
  }

  depends_on = [module.databases]
}
