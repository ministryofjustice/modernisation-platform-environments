locals {
  # role exists in laa-test only; the test workspace trusts the development airflow cluster
  airflow_pda_enabled = local.environment == "test"

  # condition-key prefix derived from the provider arn, e.g. oidc.eks.eu-west-2.amazonaws.com/id/<id>
  airflow_pda_oidc_issuer = element(split("oidc-provider/", module.airflow_oidc.oidc_arn), 1)

  airflow_pda_glue_arn_prefix = "arn:aws:glue:${local.current_account_region}:${local.current_account_id}"

  # athena workgroup; must use managed query results so the role needs no s3 access
  airflow_pda_workgroup = "primary"

  airflow_pda_source_database = "data_claims"
  airflow_pda_source_table    = "submission"
  airflow_pda_target_database = "pda_raw"
}

# trust: only the pda workflow's service account on the airflow compute cluster

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
    resources = ["arn:aws:athena:${local.current_account_region}:${local.current_account_id}:workgroup/${local.airflow_pda_workgroup}"]
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
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_source_database}",
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_target_database}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_source_database}/${local.airflow_pda_source_table}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_target_database}/*",
    ]
  }

  statement {
    sid     = "GlueCommitIcebergDestination"
    effect  = "Allow"
    actions = ["glue:UpdateTable"]
    resources = [
      "${local.airflow_pda_glue_arn_prefix}:catalog",
      "${local.airflow_pda_glue_arn_prefix}:database/${local.airflow_pda_target_database}",
      "${local.airflow_pda_glue_arn_prefix}:table/${local.airflow_pda_target_database}/*",
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

# lake formation: source, read office codes from data_claims.submission
resource "aws_lakeformation_permissions" "airflow_pda_source_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = local.airflow_pda_source_database
  }
}

resource "aws_lakeformation_permissions" "airflow_pda_source_table" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = local.airflow_pda_source_database
    name          = local.airflow_pda_source_table
  }
}

# lake formation: destination, see pda_raw and insert into its tables

resource "aws_lakeformation_permissions" "airflow_pda_destination_database" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = local.airflow_pda_target_database
  }

  depends_on = [module.databases]
}

# wildcard covers all current and future tables in pda_raw
resource "aws_lakeformation_permissions" "airflow_pda_destination_tables" {
  count = local.airflow_pda_enabled ? 1 : 0

  principal   = aws_iam_role.airflow_pda[0].arn
  permissions = ["SELECT", "INSERT", "DESCRIBE"]

  table {
    database_name = local.airflow_pda_target_database
    wildcard      = true
  }

  depends_on = [module.databases]
}
