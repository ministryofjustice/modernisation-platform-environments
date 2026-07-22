locals {
  orphan_prefix_overrides_by_database = {}
  dbt_domain_name_by_database         = {
    "staged_mdss" = "staged"
    "check" = "quicksight"
    "validation" = "quicksight"
    "staging_fms" = "live"
    "staging_mdss" = "live"
    "intermediate_fms" = "live"
    "intermediate_mdss" = "live"
    "am_stg" = "historic"
    "buddi_stg" = "historic"
    "cap_dw_stg" = "historic"
    "emd_historic_int" = "historic"
    "historic_api_mart" = "historic"
    "histoirc_api_mart_mock" = "historic"
    "intermeidate_tasking" = "historic"
    "sar_ear_reports_mart" = "historic"
    "serco_fms_deduped" = "deduped"
    "curated_alcohol_monitoring" = "curated"
    "curated_cap_dw" = "curated"
    "curated_emsys_mvp" = "curated"
    "curated_emsys_tpims" = "curated"
    "curated_fep" = "curated"
    "curated_scram_alcohol_monitoring" = "curated"
    "g4s_atrium_curated" = "curated"
    "g4s_centurion_curated" = "curated"
    "g4s_integrity_curated" = "curated"
    "g4s_lcm_curated" = "curated"
    "g4s_tasking_curated" = "curated"
    "serco_fms_curated" = "curated"
    "acquisitive_crime" = "consumption"
    "analysis" = "consumption"
    "data_insights" = "consumption"
    "datamart" = "consumption"
    "derived" = "consumption"
  }
}

module "glue_table_optimizer" {
  source = "./modules/glue_table_optimizer"

  databases                           = local.is-development ? local.live_feed_dbs_to_grant : local.existing_dbs_to_grant
  data_bucket_lf_resource_arn         = aws_lakeformation_resource.data_bucket.arn
  optimizer_bucket_id                 = module.s3-create-a-derived-table-bucket.bucket.id
  orphan_prefix_overrides_by_database = local.orphan_prefix_overrides_by_database
  role_arn                            = aws_iam_role.glue_table_optimizer.arn
  environment                         = local.environment_shorthand
  dbt_databases                       = local.dbt_dbs_to_grant
  dbt_domain_name_by_database         = local.dbt_domain_name_by_database
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

resource "aws_iam_policy" "glue_table_optimiser_policy" {
  name   = "glue-table-optimiser-policy"
  policy = data.aws_iam_policy_document.glue_table_optimizer_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_table_optimizer_policy_attachment" {
  role       = aws_iam_role.glue_table_optimizer.name
  policy_arn = aws_iam_policy.glue_table_optimiser_policy.arn
}
