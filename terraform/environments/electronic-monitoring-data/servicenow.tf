locals {
  #checkov:skip=CKV_SECRET_6 placeholder
  servicenow_credentials_placeholder = { "USERNAME" : "placeholder", "PASSWORD" : "placeholders" }
  underscore_env                     = local.is-production ? "" : "_${local.environment_shorthand}"
}

resource "aws_secretsmanager_secret" "servicenow_credentials" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "credentials/servicenow"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "servicenow_credentials" {
  secret_id     = aws_secretsmanager_secret.servicenow_credentials.id
  secret_string = jsonencode(local.servicenow_credentials_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.servicenow_credentials]
}


data "aws_iam_policy_document" "zero_etl_source" {
  #checkov:skip=CKV_AWS_111: glue min permssions *
  #checkov:skip=CKV_AWS_356: glue min permssions *
  #checkov:skip=CKV_AWS_109: secrets
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:*"]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:credentials/servicenow*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetConnections",
      "glue:GetConnection"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:connection/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:RefreshOAuth2Tokens",
      "glue:ListEntities",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "zero_etl_target" {
  statement {
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/zero-etl/servicenow${local.underscore_env}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:CreateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:UpdateTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
      "glue:GetResourcePolicy"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*"
    ]
  }
}


data "aws_iam_policy_document" "zero_etl_logging" {
  #checkov:skip=CKV_AWS_111: logging min permssions *
  #checkov:skip=CKV_AWS_356: logging min permssions *
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["AWS/Glue/ZeroETL"]
      variable = "cloudwatch:namespace"
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

# -------------------------------------------------------
# logging policy
# -------------------------------------------------------

resource "aws_iam_policy" "zero_etl_logging" {
  name   = "zero_etl_loggin"
  policy = data.aws_iam_policy_document.zero_etl_logging.json
}

# -------------------------------------------------------
# Source role
# -------------------------------------------------------
resource "aws_iam_role" "zero_etl_snow_source" {
  name               = "zero_etl_snow_source"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_policy" "zero_etl_snow_source" {
  name   = "zero_etl_snow_source"
  policy = data.aws_iam_policy_document.zero_etl_source.json
}

resource "aws_iam_role_policy_attachment" "zero_etl_snow_source" {
  role       = aws_iam_role.zero_etl_snow_source.name
  policy_arn = aws_iam_policy.zero_etl_snow_source.arn
}

resource "aws_iam_role_policy_attachment" "zero_etl_source_logging" {
  role       = aws_iam_role.zero_etl_snow_source.name
  policy_arn = aws_iam_policy.zero_etl_logging.arn
}

# -------------------------------------------------------
# Target role
# -------------------------------------------------------
resource "aws_iam_role" "zero_etl_snow_target" {
  name               = "zero_etl_snow_target"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_policy" "zero_etl_snow_target" {
  name   = "zero_etl_snow_target"
  policy = data.aws_iam_policy_document.zero_etl_target.json
}

resource "aws_iam_role_policy_attachment" "zero_etl_target" {
  role       = aws_iam_role.zero_etl_snow_target.name
  policy_arn = aws_iam_policy.zero_etl_snow_target.arn
}

resource "aws_iam_role_policy_attachment" "zero_etl_target_logging" {
  role       = aws_iam_role.zero_etl_snow_target.name
  policy_arn = aws_iam_policy.zero_etl_logging.arn
}

resource "aws_lakeformation_permissions" "zero_etl_snow_s3_access" {
  principal   = aws_iam_role.zero_etl_snow_target.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "zero_etl_snow_db_access" {
  principal   = aws_iam_role.zero_etl_snow_target.arn
  permissions = ["ALL"]
  database {
    name = aws_glue_catalog_database.servicenow.name
  }
}

resource "aws_lakeformation_permissions" "zero_etl_snow_table_access" {
  principal   = aws_iam_role.zero_etl_snow_target.arn
  permissions = ["ALL"]
  table {
    database_name = aws_glue_catalog_database.servicenow.name
    wildcard      = true
  }
}

resource "aws_glue_catalog_database" "servicenow" {
  name         = "servicenow${local.underscore_env}"
  location_uri = "s3://${module.s3-create-a-derived-table-bucket.bucket.id}/zero-etl/servicenow${local.underscore_env}/"
}
