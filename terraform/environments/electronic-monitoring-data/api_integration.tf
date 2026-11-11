locals {
  irsa_name = local.is-development || local.is-test ? "cloud-platform-irsa-8d7b7a42d840ce59-live" : local.is-preproduction ? "cloud-platform-irsa-91f1480099494185-live" : "cloud-platform-irsa-dd6ef71b563575c8-live"
  api_integration_databases = {
    person_record = aws_glue_catalog_database.person_record
    cemo          = aws_glue_catalog_database.cemo
  }
}

module "emd_api_integration_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    data.aws_iam_roles.mod_plat_roles.arns,
    "arn:aws:iam::754256621582:role/${local.irsa_name}",
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "emd_api_integration_${local.environment_shorthand}"

  tags = local.tags
}

data "aws_iam_policy_document" "api_integration" {
  statement {
    sid       = "ListAccountAliasForEnvironmentClass"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid    = "ListAllBucketsForEnvironmentClass"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTables",
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*",
    ]
  }
  statement {
    actions = [
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:CreatePreparedStatement",
      "athena:UpdatePreparedStatement",
      "athena:GetPreparedStatement",
      "athena:ListPreparedStatements",
      "athena:DeletePreparedStatement",
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${local.env_account_id}:*/*"
    ]
  }
  statement {
    actions   = ["athena:ListWorkGroups"]
    resources = ["*"]
  }
  statement {
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      module.s3-athena-bucket.bucket.arn,
      module.s3-raw-formatted-data-bucket.bucket.arn
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "${module.s3-athena-bucket.bucket.arn}/*",
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/cemo/*",
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/person_record/*",
    ]
  }
}

resource "aws_glue_catalog_database" "person_record" {
  name = "person_record${local.db_suffix}"
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      location_uri,
      parameters,
      target_database
    ]
  }
}

resource "aws_glue_catalog_database" "cemo" {
  name = "cemo${local.db_suffix}"
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      location_uri,
      parameters,
      target_database
    ]
  }
}

resource "aws_iam_policy" "emd_api_integration_policy" {
  name_prefix = "emd-cpr-integrations"
  description = "Permissions for cpr integration."
  policy      = data.aws_iam_policy_document.api_integration.json
}

resource "aws_iam_role_policy_attachment" "emd_api_integration_permissions" {
  policy_arn = aws_iam_policy.emd_api_integration_policy.arn
  role       = module.emd_api_integration_role.iam_role_name
}

resource "aws_lakeformation_permissions" "api_integration_int_fms" {
  principal   = module.emd_api_integration_role.iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "intermediate_fms${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "api_integration_int_fms_tables" {
  principal   = module.emd_api_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "intermediate_fms${local.dbt_suffix}"
    name          = "dd_device_wearer_current"
  }
}

resource "aws_lakeformation_permissions" "cemo_integration_curated_fms" {
  principal   = module.emd_api_integration_role.iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "serco_fms_curated${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "cemo_integration_curated_fms_tables" {
  principal   = module.emd_api_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "serco_fms_curated${local.dbt_suffix}"
    name          = "x_serg2_ems_csm_case"
  }
}

resource "aws_lakeformation_permissions" "cemo_integration_curated_fms_table_wap" {
  principal   = module.emd_api_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "serco_fms_curated${local.dbt_suffix}"
    name          = "x_serg2_ems_csm_case_wap"
  }
}
