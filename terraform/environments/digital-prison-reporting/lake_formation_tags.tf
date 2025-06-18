resource "aws_iam_policy" "glue_read_and_lf_access" {
  name = "glue-read-and-lf-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "LakeFormationGetAccess",
        Effect   = "Allow",
        Action   = [
          "lakeformation:GetDataAccess"
        ],
        Resource = ["*"]
      },
      {
        Sid      = "GlueGetAccess",
        Effect   = "Allow",
        Action   = [
          "glue:GetCatalog",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ],
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/dpr_ap_integration_test_tag_dev_dbt",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/dpr_ap_integration_test_tag_dev_dbt/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_lf_access" {
  role       = "alpha_user_andrewc-moj"  
  policy_arn = aws_iam_policy.glue_read_and_lf_access.arn
}


resource "aws_lakeformation_permissions" "grant_tag_to_consumer" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons"]
  }
}

resource "aws_lakeformation_permissions" "lf_data_location_alpha" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::dpr-structured-historical-development"
  }
}

resource "aws_lakeformation_permissions" "grant_table_access_by_tag" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DESCRIBE"] 

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = aws_lakeformation_lf_tag.domain_tag.key
      values = ["prisons"]
    }
  }
}