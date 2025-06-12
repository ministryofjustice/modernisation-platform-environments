resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([
    [for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn],
    data.aws_iam_session_context.current.issuer_arn,

    # Make Data engineer/developer role a LF admin
    try(one(data.aws_iam_roles.data_engineering_roles.arns), []),
    try(one(data.aws_iam_roles.aws_iam_roles.developer_roles.arns), []),

    # Make the cross-account runner used by create-a-derived table LF admin
    aws_iam_role.dataapi_cross_role.arn
    ]
  )

  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_data_lake_settings#principal
  create_database_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}



# Create the 'domain' tag with values
resource "aws_lakeformation_lf_tag" "domain_tag" {
  key    = "domain"
  values = ["prisons", "probation", "electronic-monitoring"]
}

# Create the 'sensitive' tag - with values agreed with Justice Digital
resource "aws_lakeformation_lf_tag" "sensitive_tag" {
  key    = "sensitive"
  values = ["true", "false", "data_linking"]
}

# Domain tag: Now grant the permissions to the CaDeT cross account role
resource "aws_lakeformation_permissions" "domain_grant" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DESCRIBE", "ASSOCIATE", "GRANT_WITH_LF_TAG_EXPRESSION"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = aws_lakeformation_lf_tag.domain_tag.values
  }
}

# Sensitive tag: Now grant the permissions to the CaDeT cross account role
resource "aws_lakeformation_permissions" "sensitive_grant" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DESCRIBE", "ASSOCIATE", "GRANT_WITH_LF_TAG_EXPRESSION"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.sensitive_tag.key
    values = aws_lakeformation_lf_tag.sensitive_tag.values
  }
}

resource "aws_lakeformation_permissions" "developer_roles_get_data_access" {
  for_each    = toset(data.aws_iam_roles.developer_roles.arns)
  principal   = each.value
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-*" // Adjust this ARN as needed for your data locations
  }
}


