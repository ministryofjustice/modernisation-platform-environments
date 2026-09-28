data "aws_iam_policy_document" "glue_catalog_delete_table_versions" {
  count = local.is-test ? 0 : 1

  statement {
    effect = "Allow"
    actions = [
      "glue:DeleteTableVersion"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:schema/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/curated_prisons_history/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/preprocessed_prisons_history/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/prison_datamarts/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/prison_int/*",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/curated_prisons_history",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/preprocessed_prisons_history",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/prison_datamarts",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/prison_int"
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

# Athena API Policy
resource "aws_iam_policy" "glue_catalog_delete_table_versions" {
  count = local.is-test ? 0 : 1

  name        = "${local.short_name}-glue-catalog-delete-table-versions"
  description = "Glue Catalog Delete Table Versions Policy"
  policy      = data.aws_iam_policy_document.glue_catalog_delete_table_versions[0].json
}
# Glue Catalog Delete Table Versions attachment
resource "aws_iam_role_policy_attachment" "glue_catalog_delete_table_versions" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.glue_catalog_delete_table_versions[0].arn
}
