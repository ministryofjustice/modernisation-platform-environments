locals {
    irsa_name = local.is-development || local.is-test ? "cloud-platform-irsa-8d7b7a42d840ce59-live" : ""
}

module "emd_cpr_integration_role" {
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

  role_name = "emd_cpr_integration_${local.environment_shorthand}"

  tags = local.tags
}

data "aws_iam_policy_document" "cpr_integration" {
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
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/person_record${local.db_suffix}",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/intermediate_fms${local.dbt_suffix}",
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
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/person_record${local.db_suffix}/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/intermediate_fms${local.dbt_suffix}/*",

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

resource "aws_iam_policy" "emd_cpr_integration_policy" {
  name_prefix = "emd-cpr-integrations"
  description = "Permissions for cpr integration."
  policy      = data.aws_iam_policy_document.cpr_integration.json
}

resource "aws_iam_role_policy_attachment" "emd_cpr_integration_permissions" {
  policy_arn = aws_iam_policy.emd_cpr_integration_policy.arn
  role       = module.emd_cpr_integration_role.iam_role_name
}

resource "aws_lakeformation_permissions" "cpr_integration_int_fms" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "intermediate_fms${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "cpr_integration_int_fms_tables" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "intermediate_fms${local.dbt_suffix}"
    name          = "dd_device_wearer_current"
  }
}

resource "aws_lakeformation_permissions" "cpr_integration_db" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "person_record${local.db_suffix}"
  }
}

resource "aws_lakeformation_permissions" "cpr_integration_db_tables" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE", "CREATE_TABLE"]
  table {
    database_name = "person_record${local.db_suffix}"
    wildcard      = true
  }
}
