/*
 * Dedicated runtime identity and Athena workgroup for the LAA Provider Details API (PDA) Airflow pipeline.
 *
 * - Assumed by AP Airflow (namespace mwaa, service account laa-df-pda) through the existing EKS OIDC provider.
 * - Reads data_claims.submissions and inserts into pre-provisioned Iceberg tables in pda-raw via Athena only.
 * - Has no direct S3 access: data access is vended by Lake Formation using the storage-registration roles
 *   created by module.databases (e.g. pda-raw-s3-access).
 * - Development only.
 */

locals {
  airflow_pda_enabled = local.environment == "development"

  airflow_pda_service_account = "system:serviceaccount:mwaa:laa-df-pda"

  # Condition-key prefix derived from the provider ARN, e.g. oidc.eks.eu-west-2.amazonaws.com/id/<id>
  airflow_pda_oidc_issuer = element(split("oidc-provider/", module.airflow_oidc.oidc_arn), 1)

  airflow_pda_source_database      = "data_claims"
  airflow_pda_source_table         = "submissions"
  airflow_pda_destination_database = "pda-raw"
  airflow_pda_destination_table    = "submissions_provider_offices"

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
      values   = [local.airflow_pda_service_account]
    }
  }
}

resource "aws_iam_role" "airflow_pda" {
  count = local.airflow_pda_enabled ? 1 : 0

  name               = "airflow_pda"
  assume_role_policy = data.aws_iam_policy_document.airflow_pda_trust.json

  tags = local.tags
}

resource "aws_athena_workgroup" "laa_pda" {
  count = local.airflow_pda_enabled ? 1 : 0

  name        = "laa-pda"
  description = "Provider Details API Airflow pipeline (Managed Query Results)"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    # Results are stored in Athena-owned storage, so no customer S3 output location (or S3 access) is required.
    managed_query_results_configuration {
      enabled = true

      encryption_configuration {
        kms_key = aws_kms_key.data_lake_kms_key.arn
      }
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "airflow_pda_permissions" {
  count = local.airflow_pda_enabled ? 1 : 0

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
    resources = [aws_athena_workgroup.laa_pda[0].arn]
  }

  statement {
    sid    = "GlueReadSourceAndDestinationMetadata"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
    resources = [
      "${local.airflow_pda_glue_arn_prefix}:catalog",
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_source_database}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_source_database}/${local.airflow_pda_source_table}",
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_destination_database}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_destination_database}/${local.airflow_pda_destination_table}",
    ]
  }

  # Athena INSERT into an Iceberg table commits by updating the table's metadata_location in Glue.
  # Scoped to the single destination table; schema changes remain blocked as no Lake Formation ALTER is granted.
  statement {
    sid     = "GlueCommitIcebergDestination"
    effect  = "Allow"
    actions = ["glue:UpdateTable"]
    resources = [
      "${local.airflow_pda_glue_arn_prefix}:catalog",
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_destination_database}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_destination_database}/${local.airflow_pda_destination_table}",
    ]
  }

  statement {
    #checkov:skip=CKV_AWS_356: lakeformation:GetDataAccess does not support resource-level permissions; access is governed by Lake Formation grants
    #checkov:skip=CKV_AWS_111: lakeformation:GetDataAccess does not support resource-level permissions; access is governed by Lake Formation grants
    sid       = "LakeFormationDataAccess"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  # Data lake CMK encrypts the Glue Data Catalog and the laa-pda Managed Query Results.
  statement {
    sid    = "DataLakeKmsKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.data_lake_kms_key.arn]
  }

  # Defence in depth: the runtime identity must never access S3 directly.
  statement {
    sid       = "DenyDirectS3Access"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "airflow_pda_permissions" {
  count = local.airflow_pda_enabled ? 1 : 0

  name   = "airflow-pda-permissions"
  role   = aws_iam_role.airflow_pda[0].id
  policy = data.aws_iam_policy_document.airflow_pda_permissions[0].json
}

# Lake Formation grants. Runtime role receives no CREATE_TABLE, ALTER, DROP, DELETE or DATA_LOCATION_ACCESS.

resource "aws_lakeformation_permissions" "airflow_pda_source_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = local.airflow_pda_source_database
  }

  depends_on = [module.data_lake_settings]
}

resource "aws_lakeformation_permissions" "airflow_pda_source_table" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = local.airflow_pda_source_database
    name          = local.airflow_pda_source_table
  }

  depends_on = [module.data_lake_settings]
}

resource "aws_lakeformation_permissions" "airflow_pda_destination_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = local.airflow_pda_destination_database
  }

  depends_on = [
    module.data_lake_settings,
    module.databases,
  ]
}

# TODO: Provision the Iceberg table pda-raw.submissions_provider_offices (outside the airflow_pda identity) once
# the Provider Details schema contract is agreed, then grant airflow_pda SELECT, INSERT and DESCRIBE on it with an
# aws_lakeformation_permissions resource that depends on the table.
