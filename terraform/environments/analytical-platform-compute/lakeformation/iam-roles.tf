module "lake_formation_share_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role       = true
  role_requires_mfa = false

  role_name_prefix = "lake-formation-share"

  number_of_custom_role_policy_arns = 2

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]

  trusted_role_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-management-production"]}:root",
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-compute-development"]}:root"
  ]

  tags = local.tags
}

module "analytical_platform_control_panel_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  allow_self_assume_role = true
  trusted_role_arns = [
    format("arn:aws:iam::%s:root", local.environment_management.account_ids[local.analytical_platform_environment])

  ]
  create_role       = true
  role_requires_mfa = false
  role_name         = "analytical-platform-control-panel"

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]
  number_of_custom_role_policy_arns = 2

  tags = local.tags
}

module "analytical_platform_data_eng_dba_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  allow_self_assume_role = false
  trusted_role_arns      = formatlist("arn:aws:iam::%s:root", [local.environment_management.account_ids[local.analytical_platform_environment], local.environment_management.account_ids["analytical-platform-management-production"]])
  create_role            = true
  role_requires_mfa      = false
  role_name              = "analytical-platform-data-engineering-database-access"

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]
  number_of_custom_role_policy_arns = 2

  tags = local.tags
}

module "lake_formation_to_data_production_mojap_derived_tables_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role       = true
  role_requires_mfa = false

  role_name = "lake-formation-data-production-data-access"

  custom_role_policy_arns = [
    module.data_production_mojap_derived_bucket_lake_formation_policy.arn,
  ]

  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:SetContext"
  ]

  trusted_role_services = [
    "glue.amazonaws.com",
    "lakeformation.amazonaws.com"
  ]

  tags = local.tags
}

module "copy_apdp_cadet_metadata_to_compute_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  allow_self_assume_role = false
  trusted_role_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.eks_sso_access_role.names)}",
  ]
  create_role       = true
  role_requires_mfa = false
  role_name         = "copy-apdp-cadet-metadata-to-compute"

  custom_role_policy_arns = [module.copy_apdp_cadet_metadata_to_compute_policy.arn]

  tags = local.tags
}
