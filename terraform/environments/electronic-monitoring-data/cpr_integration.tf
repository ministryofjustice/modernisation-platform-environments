locals {
    irsa_name = local.is-development || local.is-test ? "cloud-platform-irsa-8d7b7a42d840ce59-live" : local.is-preproduction ? "cloud-platform-irsa-91f1480099494185-live" : ""
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
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAttributes",
      "s3:GetObject",
      "s3:DeleteObject"    
    ]
    resources = ["${module.s3-raw-formatted-data-bucket.bucket.arn}/staging/"]
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
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/*"
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
  permissions = ["DESCRIBE", "CREATE_TABLE"]
  database {
    name = "person_record${local.db_suffix}"
  }
}

resource "aws_lakeformation_permissions" "cpr_integration_db_tables" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "person_record${local.db_suffix}"
    wildcard      = true
  }
}


resource "aws_lakeformation_permissions" "cpr_integration_create_dbs" {
  principal   = module.emd_cpr_integration_role.iam_role_arn
  permissions = ["CREATE_DATABASE"]
  catalog_resource = true
}
