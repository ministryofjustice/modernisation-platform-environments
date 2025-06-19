
resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([
    [for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn],
    data.aws_iam_session_context.current.issuer_arn,

    # Make Data engineer role a LF admin
    try(one(data.aws_iam_roles.data_engineering_roles.arns), []),

    # Make Developer role a LF admin
    # As cannot give them the permissions (lakeformation:GetDataAccess)
    length(data.aws_iam_roles.developer_roles.arns) > 0 ? [one(data.aws_iam_roles.developer_roles.arns)] : [],

    ]
  )

   parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }

  # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_data_lake_settings#principal
  create_database_default_permissions {}
  create_table_default_permissions {}
}

# Give the cadet cross-account role LF data access
resource "aws_iam_role_policy_attachment" "dataapi_cross_role_lake_formation_data_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_data_access.arn
}

# Give the cadet cross-account role data location access
# structured and working are required
resource "aws_lakeformation_permissions" "data_location_access_structured_historical" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-structured-historical-${local.environment}"
  }
}

resource "aws_lakeformation_permissions" "data_location_access_working" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-working-${local.environment}"
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


# Share domain and sensitive tags via RAM
resource "aws_ram_resource_share" "lf_tag_share_apdp" {
  name                      = "lf-tag-share-to-apdp"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "lf_tag_share_apdp_principal" {
  principal          = "593291632749"  # APDP account ID
  resource_share_arn = aws_ram_resource_share.lf_tag_share_apdp.arn
}

resource "aws_ram_resource_association" "share_domain_tag" {
  resource_arn = "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:lf-tag/domain"
  resource_share_arn = aws_ram_resource_share.lf_tag_share_apdp.arn
}

resource "aws_ram_resource_association" "share_sensitive_tag" {
  resource_arn = "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:lf-tag/sensitive"
  resource_share_arn = aws_ram_resource_share.lf_tag_share_apdp.arn
}