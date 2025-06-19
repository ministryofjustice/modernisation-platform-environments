# Need to give database the lf_tag - cannot be done by DBT
resource "aws_lakeformation_resource_lf_tag" "tag_database_with_domain" {
  database {
    name = "dpr_ap_integration_test_tag_dev_dbt"
  }

  lf_tag {
    key   = aws_lakeformation_lf_tag.domain_tag.key
    value = "prisons"
  }
}

# Alpha user describe/associate on domain = prisons (can add more later)
resource "aws_lakeformation_permissions" "grant_tag_to_consumer" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons"]
  }
}

# Data eng role
resource "aws_lakeformation_permissions" "grant_tag_describe_to_sso_role" {
  principal   = "arn:aws:iam::593291632749:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons"]
  }
}

# Alpha user data location
resource "aws_lakeformation_permissions" "lf_data_location_alpha" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::dpr-structured-historical-development"
  }
}

# Grant external account database access by tag (all values)
resource "aws_lakeformation_permissions" "grant_database_access_by_tag" {
  principal                     = "593291632749"
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  lf_tag_policy {
    resource_type = "DATABASE"
    expression {
      key    = aws_lakeformation_lf_tag.domain_tag.key
      values = ["prisons", "probation", "electronic-monitoring"]
    }
  }
}

# Grant external account table access by tag (all values)
resource "aws_lakeformation_permissions" "grant_table_access_by_tag" {
  principal                     = "593291632749"
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = aws_lakeformation_lf_tag.domain_tag.key
      values = ["prisons", "probation", "electronic-monitoring"]
    }
  }
}