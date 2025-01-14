
locals  {
    datahub_cp_irsa_role_names = {
    dev     = "cloud-platform-irsa-33e75989394c3a08-live",
    test    = "cloud-platform-irsa-fdce67955f41b322-live",
    preprod = "cloud-platform-irsa-fe098636951cc219-live"
    }

    account_ids = {
    cloud-platform = "754256621582"
    }

    datahub_cp_irsa_role_arns = {
    for env, role_name in local.datahub_cp_irsa_role_names :
    env => "arn:aws:iam::${local.account_ids["cloud-platform"]}:role/${role_name}"
  }
}

data "aws_iam_policy_document" "datahub_read_cadet_bucket" {
  statement {
    sid    = "datahubReadCaDeTBucket"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Describe*"
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/em_data_artefacts/*",
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
}

data "aws_iam_policy_document" "datahub_ingest_glue_datasets" {
  statement {
    sid    = "datahubIngestGlueDatasets"
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetTables"
    ]
    resources = [
      "arn:aws:glue::${local.env_account_id}:catalog",
      "arn:aws:glue::${local.env_account_id}:database/*",
      "arn:aws:glue::${local.env_account_id}:table/*"
    ]
  }
}

resource "aws_iam_policy" "datahub_read_cadet_bucket" {
  name   = "datahub_read_CaDeT_bucket"
  policy = data.aws_iam_policy_document.datahub_read_cadet_bucket.json
}

resource "aws_iam_policy" "datahub_ingest_glue_datasets" {
  name   = "datahub_ingest_glue_datasets"
  policy = data.aws_iam_policy_document.datahub_ingest_glue_datasets.json
}

module "datahub_ingestion_roles" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  for_each = local.datahub_cp_irsa_role_arns

  create_role = true

  role_name = "datahub-ingestion-${each.key}"

  role_requires_mfa = false

  trusted_role_arns = [each.value]

  custom_role_policy_arns = [
    aws_iam_policy.datahub_read_cadet_bucket.arn,
    aws_iam_policy.datahub_ingest_glue_datasets.arn,
  ]
}