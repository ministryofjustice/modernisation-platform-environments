# Assign LF tag to the database
resource "aws_lakeformation_resource_lf_tag" "tag_database_with_domain" {
  database {
    name = "dpr_ap_integration_test_tag_dev_dbt"
  }

  lf_tag {
    key   = aws_lakeformation_lf_tag.domain_tag.key
    value = "prisons"
  }
}

###########################
# Data Engineering SSO Role
###########################

resource "aws_lakeformation_permissions" "grant_tag_policy_table_de_role" {
  principal   = "arn:aws:iam::593291632749:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = aws_lakeformation_lf_tag.domain_tag.key
      values = ["prisons"]
    }
  }
}

resource "aws_lakeformation_permissions" "grant_tag_access_de_role" {
  principal   = "arn:aws:iam::593291632749:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons", "probation", "electronic-monitoring"]
  }
}

###########################
# External Account Permissions
###########################

resource "aws_lakeformation_permissions" "grant_tag_access_external_account" {
  principal   = "593291632749"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons", "probation", "electronic-monitoring"]
  }
}
