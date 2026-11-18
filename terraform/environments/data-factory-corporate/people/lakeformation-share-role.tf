data "aws_iam_policy_document" "data_access_share_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"
      ]
    }
  }
}

resource "aws_iam_role" "analytical_platform_data_share" {
  name                 = "analytical-platform-data-production-share-role"
  max_session_duration = 43200
  assume_role_policy   = data.aws_iam_policy_document.data_access_share_assume_role.json
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "data_share_lakeformation_cross_account" {
  role       = aws_iam_role.analytical_platform_data_share.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}

resource "aws_iam_role_policy_attachment" "data_share_lakeformation_admin" {
  role       = aws_iam_role.analytical_platform_data_share.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}

# Allow the access workflow to delegate read access to existing and future Sherlock tables.
resource "aws_lakeformation_permissions" "data-share-sherlock-tables" {
  principal                     = aws_iam_role.analytical_platform_data_share.arn
  permissions                   = ["DESCRIBE", "SELECT"]
  permissions_with_grant_option = ["DESCRIBE", "SELECT"]

  table {
    database_name = module.sherlock_glue_database.glue_database_name
    catalog_id    = data.aws_caller_identity.current.account_id
    wildcard      = true
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}

# Delegate location access only for the explicitly registered buckets and prefixes.
resource "aws_lakeformation_permissions" "data-share-sherlock-location" {
  for_each = local.lakeformation_locations

  principal                     = aws_iam_role.analytical_platform_data_share.arn
  permissions                   = ["DATA_LOCATION_ACCESS"]
  permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn        = module.lakeformation_locations[each.key].location_arn
    catalog_id = data.aws_caller_identity.current.account_id
  }

  depends_on = [
    aws_lakeformation_data_lake_settings.your_lake_settings_name,
    module.lakeformation_locations
  ]
}

moved {
  from = aws_lakeformation_permissions.data-share-sherlock-location
  to   = aws_lakeformation_permissions.data-share-sherlock-location["sherlock"]
}