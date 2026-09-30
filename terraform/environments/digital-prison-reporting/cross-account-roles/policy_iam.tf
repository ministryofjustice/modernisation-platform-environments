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
