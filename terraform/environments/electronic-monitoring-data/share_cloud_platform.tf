locals {
  # Setting the IAM name that our Cloud Platform API will use to connect to this role

  iam-dev = local.environment_shorthand == "dev" ? [
    var.cloud-platform-iam-dev
  ] : null

  iam-test = local.environment_shorthand == "test" ? [
    var.cloud-platform-iam-dev,
    var.cloud-platform-iam-preprod,
    var.cloud-platform-iam-prod
  ] : null

  iam-preprod = local.environment_shorthand == "preprod" ? [
    var.cloud-platform-iam-preprod
  ] : null

  iam-prod = local.environment_shorthand == "prod" ? [
    var.cloud-platform-iam-prod
  ] : null

  tables_to_share = [
    "contact_history",
    "equipment_details",
    "event_history",
    "incident",
    "order_details",
    "services",
    "suspension_of_visits",
    "violations",
    "visit_details"
  ]
  table_filters = {
    for table in local.tables_to_share : table => "specials_flag=0"
  }
  specials_table_filters = {
    for table in local.tables_to_share : table => ""
  }

  resolved-cloud-platform-iam-roles = coalesce(local.iam-dev, local.iam-test, local.iam-preprod, local.iam-prod)

  # Setting glue ARNs to limit access to production API mart
  glue_arns = local.is-production ? [
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/staged_fms_${local.env_}dbt",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/staged_fms_${local.env_}dbt/*"
    ] : [
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/historic_api_mart",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/historic_api_mart/*",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/staged_fms_${local.env_}dbt",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/staged_fms_${local.env_}dbt/*"
  ]
}

variable "cloud-platform-iam-dev" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-6ab6c596b45e90b3-live"
}

variable "cloud-platform-iam-preprod" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-bca231f5681d29c6-live"
}

variable "cloud-platform-iam-prod" {
  type        = string
  description = "IAM role that our API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-7a81f92a48491ef0-live"
}

module "cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    local.resolved-cloud-platform-iam-roles,
    data.aws_iam_roles.data_engineering_roles.arns
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "cmt_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

module "specials_cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    local.resolved-cloud-platform-iam-roles,
    data.aws_iam_roles.data_engineering_roles.arns
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "specials_cmt_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

module "share_data_marts" {
  source = "./modules/lakeformation_w_data_filter"

  count                   = local.is-development ? 0 : local.is-preproduction ? 0 : 1
  table_filters           = local.table_filters
  database_name           = "historic_api_mart"
  data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
}

module "share_specials_data_marts" {
  source = "./modules/lakeformation_w_data_filter"

  count                   = local.is-development ? 0 : local.is-preproduction ? 0 : 1
  table_filters           = local.specials_table_filters
  database_name           = "historic_api_mart"
  data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
}


data "aws_iam_policy_document" "standard_athena_access" {
  statement {
    actions = [
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${local.env_account_id}:*/*"
    ]
  }
  statement {
    actions = [
      "athena:CreatePreparedStatement",
      "athena:UpdatePreparedStatement",
      "athena:GetPreparedStatement",
      "athena:ListPreparedStatements",
      "athena:DeletePreparedStatement"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${local.env_account_id}:*/*"
    ]
  }
  statement {
    actions = [
      "athena:ListWorkGroups"
    ]
    resources = [
      "*"
    ]
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
    resources = [module.s3-athena-bucket.bucket.arn]
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
    resources = ["${module.s3-athena-bucket.bucket.arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable"
    ]
    resources = local.glue_arns
  }
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${local.env_account_id}:${module.get_zipped_file_api_api.api_gateway_id}/*"]
  }
}

resource "aws_iam_policy" "standard_athena_access" {
  name_prefix = "standard_athena_access"
  description = "Standard permissions for Athena"
  policy      = data.aws_iam_policy_document.standard_athena_access.json
}

resource "aws_iam_role_policy_attachment" "standard_athena_access" {
  policy_arn = aws_iam_policy.standard_athena_access.arn
  role       = module.cmt_front_end_assumable_role.iam_role_name
}


resource "aws_iam_role_policy_attachment" "specials_role_standard_athena_access" {
  policy_arn = aws_iam_policy.standard_athena_access.arn
  role       = module.specials_cmt_front_end_assumable_role.iam_role_name
}
