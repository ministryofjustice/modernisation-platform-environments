locals {
  env_map = {
    "production"    = "prod"
    "preproduction" = "preprod"
    "test"          = "test"
    "development"   = "dev"
  }
  env_suffixes = {
    "production"    = ""
    "preproduction" = "-pp"
    "test"          = ""
    "development"   = ""
  }
  camel-sid          = join("", [for word in split("-", var.name) : title(word)])
  suffix             = var.environment != "production" ? "_${local.env_map[var.environment]}" : ""
  snake-database     = "${replace(var.database_name, "-", "_")}${local.suffix}"
  am_workaround_name = var.name == "alcohol-monitoring" ? "am" : var.name
  role_name_suffix   = var.full_reload ? "full-reload-${var.name}${local.env_suffixes[var.environment]}" : "load-${local.am_workaround_name}${local.env_suffixes[var.environment]}"
  source_bucket_paths = var.source_data_bucket != null ? [
    "${var.source_data_bucket.arn}${var.path_to_data}*/*",
    "${var.source_data_bucket.arn}/staging${var.path_to_data}*/*",
  ] : []
  list_buckets = var.source_data_bucket != null ? [
    var.source_data_bucket.arn,
    var.athena_dump_bucket.arn,
    var.cadt_bucket.arn
    ] : [
    var.athena_dump_bucket.arn,
    var.cadt_bucket.arn
  ]
  iam_policy_documents = var.secret_arn != null ? [
    data.aws_iam_policy_document.load_data.json,
    data.aws_iam_policy_document.get_secrets[0].json
  ] : [data.aws_iam_policy_document.load_data.json]
  create_stg_db = var.full_reload ? false : true
}

data "aws_iam_policy_document" "get_secrets" {
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_111
  count = var.secret_arn != null ? 1 : 0
  statement {
    sid    = "GetCredentials${var.name}"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [var.secret_arn]
  }
  statement {
    sid    = "ListAllSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "load_data" {
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_111
  statement {
    sid    = "GetFiles${local.camel-sid}"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAttributes"
    ]
    resources = flatten([
      local.source_bucket_paths,
      "${var.cadt_bucket.arn}/staging/${local.snake-database}/*",
      "${var.cadt_bucket.arn}/staging${var.path_to_data}/*",
      "${var.cadt_bucket.arn}/staging/${local.snake-database}_pipeline/*",
      "${var.cadt_bucket.arn}/staging${var.path_to_data}_pipeline/*",
      "${var.athena_dump_bucket.arn}/output/*"
    ])
  }
  statement {
    sid       = "ListDataBucket${local.camel-sid}"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = local.list_buckets
  }
  statement {
    sid    = "AthenaPermissionsForLoadData${local.camel-sid}"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GluePermissionsForLoad${local.camel-sid}"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetCatalog"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.snake-database}*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.snake-database}*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${local.snake-database}*/*",
    ]
  }
  statement {
    sid    = "GetDataAccessAndTagsForLakeFormation${local.camel-sid}"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAlias${local.camel-sid}"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucket${local.camel-sid}"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

module "ap_database_sharing" {
  source = "../ap_airflow_iam_role"

  environment          = var.environment
  role_name_suffix     = local.role_name_suffix
  role_description     = "${var.name} database permissions"
  iam_policy_documents = local.iam_policy_documents
  secret_code          = var.secret_code
  oidc_arn             = var.oidc_arn
  max_session_duration = var.max_session_duration
  new_airflow          = var.new_airflow
}

module "share_dbs_with_roles" {
  source                  = "../lakeformation_database_share"
  dbs_to_grant            = toset([local.snake-database])
  data_bucket_lf_resource = var.data_bucket_lf_resource
  role_arn                = module.ap_database_sharing.iam_role.arn
  de_role_arn             = var.de_role_arn
  db_exists               = var.db_exists
}

module "share_stg_db_with_roles" {
  source                  = "../lakeformation_database_share"
  dbs_to_grant            = toset(["${local.snake-database}_staging"])
  data_bucket_lf_resource = var.data_bucket_lf_resource
  role_arn                = module.ap_database_sharing.iam_role.arn
  de_role_arn             = var.de_role_arn
  db_exists               = !local.create_stg_db
}


resource "aws_lakeformation_permissions" "catalog_manage" {
  principal = module.ap_database_sharing.iam_role.arn

  permissions = [
    "CREATE_DATABASE",
  ]

  catalog_resource = true
}

