locals {
  env_ = "${local.environment_shorthand}_"
  iam-dev = local.environment_shorthand == "dev" ? [
    var.cloud-platform-iam-dev,
  ] : null

  iam-test = local.environment_shorthand == "test" ? [
    var.cloud-platform-iam-dev,
    var.cloud-platform-iam-preprod,
    var.cloud-platform-iam-prod,
  ] : null

  iam-preprod = local.environment_shorthand == "preprod" ? [
    var.cloud-platform-iam-preprod
  ] : null

  iam-prod = local.environment_shorthand == "prod" ? [
    var.cloud-platform-iam-prod
  ] : null

  am_tables_to_share = [
    "am_contact_history",
    "am_equipment_details",
    "am_incident",
    "am_order_details",
    "am_services",
    "am_violations",
    "am_visit_details",
  ]

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

  table_filters = merge(
    {
      for table in local.tables_to_share : table => "specials_flag=0"
    },
    local.am_table_filters
  )

  specials_table_filters = merge(
    {
      for table in local.tables_to_share : table => ""
    },
    local.am_table_filters
  )

  am_table_filters = {
    for table in local.am_tables_to_share : table => ""
  }

  resolved-cloud-platform-iam-roles = coalesce(local.iam-dev, local.iam-test, local.iam-preprod, local.iam-prod)

  # Setting glue ARNs to limit access to production API mart
  cmt_glue_arns = local.is-production ? [
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

variable "cloud-platform-crime-matching-api-iam-dev" {
  type        = string
  description = "IAM role that the crime matching API in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-6e3937460af175fd-live"
}

variable "cloud-platform-crime-matching-algorithm-iam-dev" {
  type        = string
  description = "IAM role that the crime matching algorithm in Cloud Platform will use to connect to this role."
  default     = "arn:aws:iam::754256621582:role/cloud-platform-irsa-65e2e0ef1e64c470-live"
}

resource "aws_lakeformation_resource" "data_bucket" {
  arn      = module.s3-create-a-derived-table-bucket.bucket.arn
  role_arn = module.lakeformation_registration_iam_role.arn
}


module "cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    local.resolved-cloud-platform-iam-roles,
    data.aws_iam_roles.mod_plat_roles.arns
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "cmt_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

module "acquisitive_crime_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count   = local.is-development || local.is-test ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    data.aws_iam_roles.mod_plat_roles.arns,
    [
      var.cloud-platform-crime-matching-api-iam-dev,
      var.cloud-platform-crime-matching-algorithm-iam-dev,
    ],
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "ac_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

module "specials_cmt_front_end_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.48.0"

  trusted_role_arns = flatten([
    local.resolved-cloud-platform-iam-roles,
    data.aws_iam_roles.mod_plat_roles.arns
  ])

  create_role       = true
  role_requires_mfa = false

  role_name = "specials_cmt_read_emds_data_${local.environment_shorthand}"

  tags = local.tags
}

module "share_data_marts" {
  source = "./modules/lakeformation_w_data_filter"

  count         = local.is-development ? 0 : local.is-preproduction ? 0 : 1
  table_filters = local.table_filters
  database_name = "historic_api_mart"
  extra_arns = [
    try(one(data.aws_iam_roles.mod_plat_roles.arns)),
    data.aws_iam_role.github_actions_role.arn,
    data.aws_iam_session_context.current.issuer_arn
  ]
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
}

module "share_specials_data_marts" {
  source = "./modules/lakeformation_w_data_filter"

  count         = local.is-development ? 0 : local.is-preproduction ? 0 : 1
  table_filters = local.specials_table_filters
  database_name = "historic_api_mart"
  extra_arns = [
    try(one(data.aws_iam_roles.mod_plat_roles.arns)),
    data.aws_iam_role.github_actions_role.arn,
    data.aws_iam_session_context.current.issuer_arn
  ]
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
}

resource "aws_lakeformation_permissions" "ac_allied_db" {
  count       = local.is-test ? 1 : 0
  principal   = module.acquisitive_crime_assumable_role[0].iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "allied_mdss_${local.environment_shorthand}"
  }
}

resource "aws_lakeformation_permissions" "ac_allied_tables" {
  count       = local.is-test ? 1 : 0
  principal   = module.acquisitive_crime_assumable_role[0].iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "allied_mdss_${local.environment_shorthand}"
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "ac_servicenow_db" {
  count       = local.is-test ? 1 : 0
  principal   = module.acquisitive_crime_assumable_role[0].iam_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "serco_servicenow_${local.environment_shorthand}"
  }
}

resource "aws_lakeformation_permissions" "ac_servicenow_tables" {
  count       = local.is-test ? 1 : 0
  principal   = module.acquisitive_crime_assumable_role[0].iam_role_arn
  permissions = ["SELECT", "DESCRIBE"]
  table {
    database_name = "serco_servicenow_${local.environment_shorthand}"
    wildcard      = true
  }
}


data "aws_iam_policy_document" "standard_athena_access" {
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
}

data "aws_iam_policy_document" "cmt_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable"
    ]
    resources = local.cmt_glue_arns
  }
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${local.env_account_id}:${module.get_zipped_file_api_api.api_gateway_id}/*"]
  }
}



data "aws_iam_policy_document" "ac_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      # Glue uses a heirarchical system of permissions. Permissions must be granted at
      # every higher level to work in the lower levels!
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable",
    ]
    resources = ["arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable",
    ]
    resources = local.is-development || local.is-test ? ["arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*"] : []
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTables",
      "glue:GetTable",
    ]
    resources = local.is-development || local.is-test ? ["arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*"] : []
  }
}

resource "aws_iam_policy" "standard_athena_access" {
  name_prefix = "standard_athena_access"
  description = "Standard permissions for Athena"
  policy      = data.aws_iam_policy_document.standard_athena_access.json
}

resource "aws_iam_policy" "cmt_specific_access" {
  name_prefix = "cmt_specific_access"
  description = "Access to the Glue tables and APIs required by CMT."
  policy      = data.aws_iam_policy_document.cmt_permissions.json
}

resource "aws_iam_policy" "ac_specific_access" {
  count       = local.is-development || local.is-test ? 1 : 0
  name_prefix = "ac_specific_access"
  description = "Access to the Glue tables required by Acquisitive Crime."
  policy      = data.aws_iam_policy_document.ac_permissions.json
}

resource "aws_iam_role_policy_attachment" "standard_athena_access" {
  policy_arn = aws_iam_policy.standard_athena_access.arn
  role       = module.cmt_front_end_assumable_role.iam_role_name
}

resource "aws_iam_role_policy_attachment" "cmt_specific_access" {
  policy_arn = aws_iam_policy.cmt_specific_access.arn
  role       = module.cmt_front_end_assumable_role.iam_role_name
}


resource "aws_iam_role_policy_attachment" "specials_role_standard_athena_access" {
  policy_arn = aws_iam_policy.standard_athena_access.arn
  role       = module.specials_cmt_front_end_assumable_role.iam_role_name
}

resource "aws_iam_role_policy_attachment" "standard_athena_access_ac" {
  count      = local.is-development || local.is-test ? 1 : 0
  policy_arn = aws_iam_policy.standard_athena_access.arn
  role       = module.acquisitive_crime_assumable_role[0].iam_role_name
}

resource "aws_iam_role_policy_attachment" "ac_specific_access" {
  count      = local.is-development || local.is-test ? 1 : 0
  policy_arn = aws_iam_policy.ac_specific_access[0].arn
  role       = module.acquisitive_crime_assumable_role[0].iam_role_name
}
