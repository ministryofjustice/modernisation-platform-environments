module "data_lake_settings" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-settings?ref=feat/data-lake-storage"

  admins = [
    /* Modernisation Platform */
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
    /* SSO */
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}",
  ]

  trusted_resource_owners = [
    for factory in try(tolist(local.lakeformation_configuration.factories), keys(local.lakeformation_configuration.factories)) : local.environment_management.account_ids[factory]
  ]
}
