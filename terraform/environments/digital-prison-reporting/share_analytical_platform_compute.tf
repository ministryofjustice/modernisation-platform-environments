
# LakeFormation LFTag permissions
# Policy Document
data "aws_iam_policy_document" "lake_formation_lftag_access" {
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  statement {
    actions = [
      "lakeformation:AddLFTagsToResource",
      "lakeformation:RemoveLFTagsFromResource",
      "lakeformation:GetResourceLFTags",
      "lakeformation:ListLFTags",
      "lakeformation:GetLFTag",
      "lakeformation:SearchTablesByLFTags",
      "lakeformation:SearchDatabasesByLFTags",
      "lakeformation:ListDataCellsFilter",
      "lakeformation:CreateDataCellsFilter",
      "lakeformation:GetDataCellsFilter",
      "lakeformation:UpdateDataCellsFilter",
      "lakeformation:DeleteDataCellsFilter",
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource",
    ]
    resources = [
      "*"
    ]
  }
}

# access glue tables and start athena queries
data "aws_iam_policy_document" "unlimited_athena_query" {
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
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
      "athena:ListWorkGroups"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions   = ["s3:GetBucketLocation"]
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
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/*",
      "${module.s3-athena-bucket.bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      module.s3-athena-bucket.bucket.arn,
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:List*",
      "glue:DeleteTable",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:schema/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*"
    ]
  }
  statement {
    effect = "Deny"
    actions = [
      "glue:DeleteDatabase",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/raw_archive",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/raw_archive/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/curated",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/curated/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/raw",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/raw/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/structured",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/structured/*"
    ]
  }
  statement {
    sid       = "ListAccountAliasDBT"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucketDBT"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ram_shares" {
  statement {
    effect = "Allow"
    actions = [
      "ram:AssociateResourceShare",
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare",
      "ram:DisassociateResourceShare",
      "ram:GetResourceShares",
      "ram:UpdateResourceShare",
      "ram:AssociateResourceSharePermission",
      "ram:DisassociateResourceSharePermission",
      "ram:ListResourceSharePermissions"
    ]
    resources = [
      "arn:aws:ram:${data.aws_region.current.name}:${local.env_account_id}:resource-share/*"
    ]
  }
}

# Lake Formation LFTag Access Attachement
resource "aws_iam_role_policy_attachment" "lake_formation_lftag_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_lftag_access.arn
}

# Athena Access Attachement
resource "aws_iam_role_policy_attachment" "unlimited_athena_query" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.unlimited_athena_query.arn
}

resource "aws_iam_role_policy_attachment" "ram_shares" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.ram_shares.arn
}

resource "aws_iam_policy" "unlimited_athena_query" {
  name        = "${local.environment_shorthand}-unlimited-athena-query"
  description = "Athena Access Policy"
  policy      = data.aws_iam_policy_document.unlimited_athena_query.json
}

resource "aws_iam_policy" "lake_formation_lftag_access" {
  name        = "${local.environment_shorthand}-lake-formation-lftag-access"
  description = "LakeFormation LFTag Access Policy"
  policy      = data.aws_iam_policy_document.lake_formation_lftag_access.json
}

resource "aws_iam_policy" "ram_shares" {
  name        = "${local.environment_shorthand}-ram-shares"
  description = "RAM Shares Access Policy"
  policy      = data.aws_iam_policy_document.ram_shares.json
}

data "aws_iam_policy_document" "allow_airflow_ssh_key" {
  for_each = local.analytical_platform_share
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      data.aws_secretsmanager_secret.airflow_ssh_secret.arn
    ]
  }
}

resource "aws_iam_role_policy" "analytical_platform_secret_share_policy_attachment" {
  for_each = local.analytical_platform_share
  name     = "analytical-platform-data-production-secrets-allow-policy"
  role     = aws_iam_role.analytical_platform_share_role[each.key].name
  policy   = data.aws_iam_policy_document.allow_airflow_ssh_key[each.key].json
}

resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment_lf_perms" {
  for_each = local.analytical_platform_share

  role       = aws_iam_role.analytical_platform_share_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}

module "share_dbs_with_roles" {
  count                   = local.is-development ? 0 : 1
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = local.dbs_to_grant
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = aws_iam_role.dataapi_cross_role.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))
}

resource "aws_lakeformation_resource" "rds_bucket" {
  arn = module.s3-dms-target-store-bucket.bucket.arn
}

## module "share_non_cadt_dbs_with_roles" {
##  count                   = local.is-production ? 1 : 0
##  source                  = "./modules/lakeformation_database_share"
##  dbs_to_grant            = ["dfoo_bar_ham_spam_eggs"]
##  data_bucket_lf_resource = aws_lakeformation_resource.rds_bucket.arn
##  role_arn                = aws_iam_role.dataapi_cross_role.arn
##  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))
## }


data "aws_secretsmanager_secret" "airflow_ssh_secret" {
  name = aws_secretsmanager_secret.airflow_secret[0].id

  depends_on = [aws_secretsmanager_secret_version.airflow_ssh_secret]
}

data "aws_secretsmanager_secret_version" "airflow_ssh_secret" {
  secret_id = data.aws_secretsmanager_secret.airflow_secret.id

  depends_on = [aws_secretsmanager_secret.airflow_ssh_secret]
}


## DBT Analytics EKS Cluster Identifier
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "airflow_ssh_secret" {
  count = local.is-preproduction || local.is-production ? 1 : 0

  secret_id     = aws_secretsmanager_secret.airflow_ssh_secret[0].id
  secret_string = jsonencode(local.airflow_cadt_secret_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.airflow_ssh_secret]
}

resource "aws_secretsmanager_secret" "airflow_ssh_secret" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  count = local.is-preproduction || local.is-production ? 1 : 0

  name = "/alpha/airflow/airflow_cadet_deployments/cadet_repo_key/"

  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}
