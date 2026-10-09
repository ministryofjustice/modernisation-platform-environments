data "aws_iam_policy_document" "glue_catalog_delete_table_versions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:DeleteTableVersion"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/*"
    ]
  }
  statement {
    effect = "Deny"
    actions = [
      "glue:DeleteTableVersion"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/raw_archive",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/raw_archive/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/curated",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/curated/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/raw",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/raw/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/structured",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/structured/*"
    ]
  }
}

resource "aws_iam_policy" "glue_catalog_delete_table_versions" {
  name        = "${local.short_name}-glue-catalog-delete-table-versions"
  description = "Glue Catalog Delete Table Versions Policy"
  policy      = data.aws_iam_policy_document.glue_catalog_delete_table_versions.json
}

resource "aws_iam_role_policy_attachment" "glue_catalog_delete_table_versions" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  role       = data.aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.glue_catalog_delete_table_versions.arn
}

# Protect glue data catalogs and S3 buckets and objects
data "aws_iam_policy_document" "glue_s3_deny" {
  statement {
    sid    = "DenyDataHubGlueCatalog"
    effect = "Deny"
    actions = [
      "glue:Delete*",
      "glue:Update*",
      "glue:Create*",
      "glue:BatchDelete*",
      "glue:BatchCreate*",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/raw_archive",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/raw_archive/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/curated",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/curated/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/raw",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/raw/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/structured",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/structured/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/reconciliation",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/reconciliation/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/prisons",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/prisons/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/domain",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/domain/*",
    ]
  }

  statement {
    sid    = "DenyDataHubS3"
    effect = "Deny"
    actions = [
      "s3:Delete*",
      "s3:Put*"
    ]
    resources = [
      "arn:aws:s3:::-${local.short_name}-curated-zone-${local.environment}",
      "arn:aws:s3:::-${local.short_name}-curated-zone-${local.environment}/*",
      "arn:aws:s3:::-${local.short_name}-structured-zone-${local.environment}",
      "arn:aws:s3:::-${local.short_name}-structured-zone-${local.environment}/*",
      "arn:aws:s3:::-${local.short_name}-raw-zone-${local.environment}",
      "arn:aws:s3:::-${local.short_name}-raw-zone-${local.environment}/*",
      "arn:aws:s3:::-${local.short_name}-raw-archive-${local.environment}",
      "arn:aws:s3:::-${local.short_name}-raw-archive-${local.environment}/*",
      "arn:aws:s3:::-${local.short_name}-domain-${local.environment}",
      "arn:aws:s3:::-${local.short_name}-domain-${local.environment}/*"
    ]
  }
}

resource "aws_iam_policy" "deny_glue_s3" {
  count = local.is-test ? 0 : 1

  name        = "${local.short_name}-deny_glue_s3"
  description = "Glue Catalog and S3 Deny Policy"
  policy      = data.aws_iam_policy_document.glue_s3_deny.json
}

resource "aws_iam_role_policy_attachment" "deny_glue_s3_de_role" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = one(data.aws_iam_roles.data_engineering_roles[0].names)
  policy_arn = aws_iam_policy.deny_glue_s3[0].arn
}

resource "aws_iam_role_policy_attachment" "deny_glue_s3_cross_account_role" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  role       = data.aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.deny_glue_s3[0].arn
}

resource "aws_iam_role_policy_attachment" "deny_glue_s3_ae_role" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test || local.is-development ? 0 : 1

  role       = one(data.aws_iam_roles.analytics_engineering_roles[0].names)
  policy_arn = aws_iam_policy.deny_glue_s3[0].arn
}
