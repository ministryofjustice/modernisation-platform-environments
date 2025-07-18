data "aws_secretsmanager_secret_version" "home_office_account_id" {
  secret_id = aws_secretsmanager_secret.home_office_account_id.id
}

locals {
    ho_role_arn = "arn:aws:iam::${data.aws_secretsmanager_secret_version.home_office_account_id.secret_string}:role/DACC-DataScience-TL"
}

resource "aws_lakeformation_permissions" "home_office_share_bucket" {
  count = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "home_office_share_database" {
  count = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["DESCRIBE"]
  database {
    name = "g4s_gps"
  }
}

resource "aws_lakeformation_permissions" "home_office_share_table" {
  count = local.is-production ? 1 : 0
  principal   = local.ho_role_arn
  permissions = ["SELECT"]
  table {
    database_name = "g4s_gps"
    name          = "ho_subject_positions"
  }
}
