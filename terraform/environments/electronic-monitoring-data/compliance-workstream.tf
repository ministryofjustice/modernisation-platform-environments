locals {
    compliance_accounts = local.is-development || local.is-test ? 1 : 0
}
module "compliance_role" {
  count   = local.compliance_accounts
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "em-compliance-${local.environment_shorthand}"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      principals = [{
            type = "AWS"
            identifiers = [try(one(data.aws_iam_roles.mod_plat_roles.arns))]
        },]
    }
  }

  policies = {
    custom = module.compliance_policy.arn
  }

  tags = local.tags
}

module "compliance_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "em-compliance-${local.environment_shorthand}"

  policy = data.aws_iam_policy_document.compliance_athena_access.json

  tags = local.tags
}

resource "aws_athena_workgroup" "compliance" {
  name        = format("%s-complaince", local.env_account_id)
  description = "An Athena workgroup for the complaiance, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 10737418240 # 10 GB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/compliance/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

data "aws_iam_policy_document" "compliance_athena_access" {
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
    resources = [aws_athena_workgroup.compliance.arn]
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
    resources = ["${module.s3-athena-bucket.bucket.arn}/output/compliance/*"]
  }
  statement {
    actions = [
      "glue:GetDatabases",
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetTable"
    ]
    resources = [
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/staged_mdss${local.dbt_suffix}",
    "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/staged_mdss${local.dbt_suffix}/*"
    ]
  }
}

resource "aws_lakeformation_permissions" "em_compliance_db_access" {
  count = local.compliance_accounts
  principal   = module.compliance_role[0].arn
  permissions = ["DESCRIBE"]
  database {
    name = "staged_mdss${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "em_compliance_tb_access" {
  count = local.compliance_accounts
  principal   = module.compliance_role[0].arn
  permissions = ["DESCRIBE"]
  table {
    database_name = "staged_mdss${local.dbt_suffix}"
    name          = "event"
  }
}

resource "aws_lakeformation_data_cells_filter" "compliance_data_filter" {
  count = local.compliance_accounts
  table_data {
    database_name    = "staged_mdss${local.dbt_suffix}"
    name             = "filter-for-staged_mdss${local.dbt_suffix}-event-table"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = "event"
    column_wildcard {}
    row_filter {
      filter_expression = "device_id in (1121)"
    }
  }
}

resource "aws_lakeformation_permissions" "em_compliance_s3_access" {
  count       = local.compliance_accounts
  principal   = module.compliance_role[0].arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = module.s3-create-a-derived-table-bucket.bucket.arn
  }
}

resource "aws_lakeformation_permissions" "em_compliance_row_access" {
  count = local.compliance_accounts
  principal   = module.compliance_role[0].arn
  permissions = ["DESCRIBE", "SELECT"]
  data_cells_filter {
    database_name    = "staged_mdss${local.dbt_suffix}"
    name             = "filter-for-staged_mdss${local.dbt_suffix}-event-table"
    table_catalog_id = data.aws_caller_identity.current.account_id
    table_name       = "event"
  }
}
