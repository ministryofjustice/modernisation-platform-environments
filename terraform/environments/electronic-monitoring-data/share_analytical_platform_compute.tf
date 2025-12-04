locals {
  analytical_platform_share = can(local.application_data.accounts[local.environment].analytical_platform_share) ? { for share in local.application_data.accounts[local.environment].analytical_platform_share : share.target_account_name => share } : {}
  enable_dbt_k8s_secrets    = local.application_data.accounts[local.environment].enable_dbt_k8s_secrets
  dbt_k8s_secrets_placeholder = {
    oidc_cluster_identifier = "placeholder2"
  }
  dbt_suffix = local.is-production ? "" : "_${local.environment_shorthand}_dbt"
  suffix     = local.is-production ? "" : local.is-preproduction ? "-pp" : local.is-test ? "-test" : "-dev"
  db_suffix  = local.is-production ? "" : "_${local.environment_shorthand}"
  dbt_dbs = [
    "staged_fms",
    "staged_mdss",
    "preprocessed_fms",
    "curated_fms",
    "staging_fms",
    "staging_mdss",
    "intermediate_fms",
    "intermediate_mdss",
    "datamart",
    "derived",
    "test_results",
    "serco_servicenow_deduped",
    "serco_servicenow_curated",
    "serco_fms",
    "serco_fms_deduped",
    "serco_fms_curated",
  ]
  live_feeds_dbs = [
    "serco_fms",
    "allied_mdss",
    "serco_servicenow",
  ]
  historic_source_dbs = local.is-production ? [
    "buddi_buddi",
    "capita_alcohol_monitoring",
    "capita_blob_storage",
    "g4s_atrium",
    "g4s_atrium_unstructured",
    "g4s_cap_dw",
    "g4s_centurion",
    "g4s_emsys_mvp",
    "g4s_emsys_tpims",
    "g4s_fep",
    "g4s_integrity",
    "g4s_lcm_archive",
    "g4s_tasking",
    "scram_alcohol_monitoring",
    "g4s_lcm",
  ] : local.is-development ? ["test"] : []

  prod_dbs_to_grant = local.is-production ? [
    "am_stg",
    "buddi_stg",
    "cap_dw_stg",
    "emd_historic_int",
    "historic_api_mart",
    "historic_api_mart_mock",
    "historic_ears_and_sars_int",
    "historic_ears_and_sars_mart",
    "emsys_mvp_stg",
    "emsys_tpims_stg",
    "sar_ear_reports_mart",
    "preprocessed_alcohol_monitoring",
    "staged_alcohol_monitoring",
    "preprocessed_cap_dw",
    "staged_cap_dw",
    "curated_emsys_mvp",
    "preprocessed_emsys_mvp",
    "staged_emsys_mvp",
    "preprocessed_emsys_tpims",
    "staged_emsys_tpims",
    "preprocessed_scram_alcohol_monitoring",
    "staged_scram_alcohol_monitoring",
    "g4s_atrium_curated",
    "g4s_centurion_curated",
    "g4s_tasking_curated",
    "g4s_integrity_curated",
    "curated_fep",
    "g4s_lcm_archive_curated",
    "g4s_lcm_curated",
  ] : []

   deployed_prod_dbs = local.is-production ? [
    "intermediate_tasking",
    "intermediate_tasking_historic_dev_dbt",
  ] : []
  dev_dbs_to_grant       = local.is-production ? [for db in local.prod_dbs_to_grant : "${db}_historic_dev_dbt"] : []
  dbt_dbs_to_grant       = [for db in local.dbt_dbs : "${db}${local.dbt_suffix}"]
  live_feed_dbs_to_grant = [for db in local.live_feeds_dbs : "${db}${local.db_suffix}"]
  dbs_to_grant           = toset(flatten([local.prod_dbs_to_grant, local.dev_dbs_to_grant, local.dbt_dbs_to_grant]))


  existing_dbs_to_grant  = toset(flatten([local.live_feed_dbs_to_grant, local.historic_source_dbs, deployed_prod_dbs]))
}

# Source Analytics DBT Secrets
data "aws_secretsmanager_secret" "dbt_secrets" {
  name = aws_secretsmanager_secret.dbt_secrets[0].id

  depends_on = [aws_secretsmanager_secret_version.dbt_secrets]
}

data "aws_secretsmanager_secret_version" "dbt_secrets" {
  secret_id = data.aws_secretsmanager_secret.dbt_secrets.id

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}


# Retrieves the source role of terraform's current caller identity
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}


## DBT Analytics EKS Cluster Identifier
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "dbt_secrets" {
  count = local.enable_dbt_k8s_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.dbt_secrets[0].id
  secret_string = jsonencode(local.dbt_k8s_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "dbt_secrets" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  count = local.enable_dbt_k8s_secrets ? 1 : 0

  name = "external/analytics_platform/k8s_dbt_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      Name          = "external/cloud_platform/k8s_auth"
      Resource_Type = "Secrets"
      Source        = "Analytics-Platform"
    }
  )
}

# TLS Certificate for OIDC URL, DBT K8s Platform
data "tls_certificate" "dbt_analytics" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}"
}


## OIDC, OpenID Connect
resource "aws_iam_openid_connect_provider" "cluster" {
  count           = local.is-production || local.is-preproduction ? 0 : 1
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.dbt_analytics.certificates[0].sha1_fingerprint]
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}"
}

## Role
## CrossAccount DataAPI Cross Account Role,
# CrossAccount DataAPI Assume Policy
data "aws_iam_policy_document" "dataapi_cross_assume" {
  #checkov:skip=CKV_AWS_110:Ensure IAM policies does not allow privilege escalation
  #checkov:skip=CKV_AWS_358:OIDC trust policies only allows actions from a specific known organization Already
  #checkov:skip=CKV_AWS_107:Ensure IAM policies does not allow credentials exposure
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_1
  #checkov:skip=CKV_AWS_283
  #checkov:skip=CKV_AWS_49
  #checkov:skip=CKV_AWS_108

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"] # account id for cloud platform, so can use in AP control panel
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.is-production || local.is-preproduction ? aws_iam_openid_connect_provider.analytical_platform_compute.arn : aws_iam_openid_connect_provider.cluster[0].arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:actions-runners:actions-runner-mojas-create-a-derived-table-emds${local.suffix}"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:aud"
    }
  }
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.analytical_platform_compute.arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:mwaa:electronic-monitoring-data-store-cadet"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.airflow_secret.secret_string)["oidc_cluster_identifier"]}:aud"
    }
  }
}

# Role used in create a derived table 
resource "aws_iam_role" "dataapi_cross_role" {
  #checkov:skip=CKV_AWS_61:Ensure IAM policies does not allow data exfiltration
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  name                  = "${local.environment_shorthand}-data-api-cross-account-role"
  description           = "Data API Cross Account Role"
  assume_role_policy    = data.aws_iam_policy_document.dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      Name           = "${local.environment_shorthand}-data-api-cross-account-role"
      Resource_Type  = "iam"
      Resource_Group = "Front-End"
    }
  )
}


# LakeFormation Data Access
# Policy Document

data "aws_iam_policy_document" "lake_formation_data_access" {
  statement {
    actions = [
      "lakeformation:GetDataAccess"
    ]
    resources = [
      "*"
    ]
  }
}


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



# Lake Formation Data Access Attachement
resource "aws_iam_role_policy_attachment" "lake_formation_data_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_data_access.arn
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


resource "aws_iam_policy" "lake_formation_data_access" {
  name        = "${local.environment_shorthand}-lake-formation-data-access"
  description = "LakeFormation Get Data Access Policy"
  policy      = data.aws_iam_policy_document.lake_formation_data_access.json
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

# Analytical Platform Share Policy & Role
data "aws_iam_policy_document" "analytical_platform_share_policy" {
  for_each = local.analytical_platform_share

  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource"
    ]
    resources = [
      #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
      "arn:aws:lakeformation:${data.aws_region.current.name}:${local.env_account_id}:catalog:${local.env_account_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${local.env_account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
    ]
  }
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ram:AssociateResourceShare",
      "ram:AssociateResourceSharePermission",
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare",
      "ram:DisassociateResourceShare",
      "ram:DisassociateResourceSharePermission",
      "ram:GetResourceShares",
      "ram:ListResourceSharePermissions",
      "ram:UpdateResourceShare",
    ]
    resources = [
      "arn:aws:ram:${data.aws_region.current.name}:${local.env_account_id}:resource-share/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition"
    ]
    resources = flatten([
      for resource in each.value.resource_shares : [
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/${resource.glue_database}",
        formatlist("arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/${resource.glue_database}/%s", resource.glue_tables),
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog"
      ]
    ])
  }
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

data "aws_iam_policy_document" "ap_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/data-engineering-datalake-access:ref:refs/heads/*"]
    }
  }
}

resource "aws_iam_role" "analytical_platform_share_role" {
  for_each = local.analytical_platform_share

  name                 = "${each.value.target_account_name}-share-role"
  max_session_duration = 12 * 60 * 60
  assume_role_policy   = data.aws_iam_policy_document.ap_assume_role.json
}

resource "aws_iam_role_policy" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  name   = "${each.value.target_account_name}-share-policy"
  role   = aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.allow_airflow_ssh_key[each.key].json
}

resource "aws_iam_role_policy" "analytical_platform_secret_share_policy_attachment" {
  for_each = local.analytical_platform_share
  name     = "analytical-platform-data-production-secrets-allow-policy"
  role     = aws_iam_role.analytical_platform_share_role[each.key].name
  policy   = data.aws_iam_policy_document.allow_airflow_ssh_key[each.key].json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  role       = aws_iam_role.analytical_platform_share_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
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

module "share_existing_dbs_with_roles" {
  count                   = local.is-development ? 0 : 1
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = local.existing_dbs_to_grant
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = aws_iam_role.dataapi_cross_role.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))
  db_exists               = true
}

resource "aws_lakeformation_resource" "rds_bucket" {
  arn = module.s3-dms-target-store-bucket.bucket.arn
}

module "share_non_cadt_dbs_with_roles" {
  count                   = local.is-production ? 1 : 0
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = ["dms_dbo_g4s_emsys_mvp"]
  data_bucket_lf_resource = aws_lakeformation_resource.rds_bucket.arn
  role_arn                = aws_iam_role.dataapi_cross_role.arn
  de_role_arn             = try(one(data.aws_iam_roles.mod_plat_roles.arns))
}


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
