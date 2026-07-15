locals {
  orphan_prefix_overrides_by_database = {}
  dbt_databases                       = setintersection(
    setsubtract(local.dbs_to_grant, toset(local.test_dbs_to_grant)),
    local.existing_dbs_to_grant
  )
  dbt_domain_name_by_database         = {
    # leaving the domains here, need to do a mapping 
    # consumption
    # curated
    # deduped
    # fms
    # historic
    # intermediate_layer
    # live
    # preprocessed
    # quicksight
    # staged
    # staging
  }
}

module "glue_table_optimizer" {
  source = "./modules/glue_table_optimizer"

  databases                           = local.is-development ? local.live_feeds_dbs : local.existing_dbs_to_grant
  data_bucket_lf_resource_arn         = aws_lakeformation_resource.data_bucket.arn
  optimizer_bucket_id                 = module.s3-create-a-derived-table-bucket.bucket.id
  orphan_prefix_overrides_by_database = local.orphan_prefix_overrides_by_database
  role_arn                            = aws_iam_role.glue_table_optimizer.arn
  environment                         = local.environment_shorthand
  dbt_databases                       = local.dbt_databases
  dbt_domain_name_by_database         = local.dbt_domain_name_by_database
}

moved {
  from = aws_glue_catalog_table_optimizer.standard_compaction
  to   = module.glue_table_optimizer.aws_glue_catalog_table_optimizer.standard_compaction
}

moved {
  from = aws_glue_catalog_table_optimizer.standard_retention
  to   = module.glue_table_optimizer.aws_glue_catalog_table_optimizer.standard_retention
}

moved {
  from = aws_glue_catalog_table_optimizer.standard_orphan_file_deletion
  to   = module.glue_table_optimizer.aws_glue_catalog_table_optimizer.standard_orphan_file_deletion
}

moved {
  from = aws_lakeformation_permissions.glue_table_optimizer_permissions
  to   = module.glue_table_optimizer.aws_lakeformation_permissions.glue_table_optimizer_permissions
}

moved {
  from = aws_lakeformation_permissions.glue_table_optimizer_table_permissions
  to   = module.glue_table_optimizer.aws_lakeformation_permissions.glue_table_optimizer_table_permissions
}

moved {
  from = aws_lakeformation_permissions.glue_table_optimizer_database_permissions
  to   = module.glue_table_optimizer.aws_lakeformation_permissions.glue_table_optimizer_database_permissions
}

data "aws_iam_policy_document" "glue_table_optimizer_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_table_optimizer" {
  name               = "glue-table-optimizer-role"
  assume_role_policy = data.aws_iam_policy_document.glue_table_optimizer_assume_role_policy.json
}

data "aws_iam_policy_document" "glue_table_optimizer_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:UpdateTable",
      "glue:GetTable",
      "glue:CreateTableOptimizer",
      "glue:GetTableOptimizer",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-compaction/logs:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-retention/logs:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-orphan-file-deletion/logs:*"
    ]
  }
}

resource "aws_iam_policy" "glue_table_optimizer_policy" {
  name   = "glue-table-optimizer-policy"
  policy = data.aws_iam_policy_document.glue_table_optimizer_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_table_optimizer_policy_attachment" {
  role       = aws_iam_role.glue_table_optimizer.name
  policy_arn = aws_iam_policy.glue_table_optimizer_policy.arn
}
