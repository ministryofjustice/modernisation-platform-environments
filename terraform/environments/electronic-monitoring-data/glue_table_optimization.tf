module "glue_table_optimiser" {
  source = "./modules/glue_table_optimiser"

  databases                           = local.live_feed_dbs_to_grant
  optimizer_bucket_id                 = module.s3-create-a-derived-table-bucket.bucket.id
  role_arn                            = aws_iam_role.glue_table_optimiser.arn
  environment                         = local.environment_shorthand
  dbt_databases                       = local.dbt_dbs_to_grant
}


data "aws_iam_policy_document" "glue_table_optimiser_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_table_optimiser" {
  name               = "glue-table-optimizer-role"
  assume_role_policy = data.aws_iam_policy_document.glue_table_optimiser_assume_role_policy.json
}

data "aws_iam_policy_document" "glue_table_optimiser_policy" {
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

resource "aws_iam_policy" "glue_table_optimiser_policy" {
  name   = "glue-table-optimiser-policy"
  policy = data.aws_iam_policy_document.glue_table_optimiser_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_table_optimiser_policy_attachment" {
  role       = aws_iam_role.glue_table_optimiser.name
  policy_arn = aws_iam_policy.glue_table_optimiser_policy.arn
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_permissions" {
  principal   = aws_iam_role.glue_table_optimiser.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_table_permissions" {
  for_each    = setunion(local.live_feed_dbs_to_grant, local.dbt_dbs_to_grant)
  principal   = aws_iam_role.glue_table_optimiser.arn
  permissions = ["ALTER", "DESCRIBE", "INSERT", "DELETE"]

  table {
    database_name = each.key
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_database_permissions" {
  for_each    = setunion(local.live_feed_dbs_to_grant, local.dbt_dbs_to_grant)
  principal   = aws_iam_role.glue_table_optimiser.arn
  permissions = ["DESCRIBE"]

  database {
    name = each.key
  }
}
