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


# Data eng role
# This let's the DE role see the tag on the consumer account
resource "aws_lakeformation_permissions" "grant_tag_describe_to_sso_role" {
  principal   = "arn:aws:iam::593291632749:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons", "probation", "electronic-monitoring"]
  }
}


# External account tag
resource "aws_lakeformation_permissions" "grant_tag_access_to_external_account" {
  principal   = "593291632749"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons", "probation", "electronic-monitoring"]
  }
}


# Grant external account  account database access by tag (all values)
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