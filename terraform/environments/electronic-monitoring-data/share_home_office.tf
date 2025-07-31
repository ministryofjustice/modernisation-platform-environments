data "aws_secretsmanager_secret_version" "home_office_account_id" {
  count     = local.is-production ? 1 : 0
  secret_id = aws_secretsmanager_secret.home_office_account_id[0].id
}

locals {
  ho_acct_id  = local.is-production ? data.aws_secretsmanager_secret_version.home_office_account_id[0].secret_string : "000000000000"
  ho_role_arn = "arn:aws:iam::${local.ho_acct_id}:role/DACC-DataScience-TL"
  ho_admin_arn = "arn:aws:iam::${local.ho_acct_id}:role/HO-FullAdmin"
}

resource "aws_lakeformation_permissions" "home_office_share_bucket" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "home_office_share_database" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "g4s_gps"
  }
}

resource "aws_lakeformation_permissions" "home_office_share_table" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["SELECT"]
  table {
    database_name = "g4s_gps"
    name          = "ho_subject_positions"
  }
}

resource "aws_lakeformation_permissions" "home_office_admin_share_bucket" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_admin_arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "home_office_admin_share_database" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_admin_arn
  permissions = ["DESCRIBE"]
  database {
    name = "g4s_gps"
  }
}

resource "aws_lakeformation_permissions" "home_office_admin_share_table" {
  count       = local.is-production ? 1 : 0
  principal   = local.ho_admin_arn
  permissions = ["SELECT"]
  table {
    database_name = "g4s_gps"
    name          = "ho_subject_positions"
  }
}
