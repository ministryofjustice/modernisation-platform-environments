module "lake_formation_share_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "lake-formation-share"
  use_name_prefix = false


  policies = {
    analytical_platform_lake_formation_share_policy = module.analytical_platform_lake_formation_share_policy.arn
    aws_lakeformation_policy                        = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  }

  trust_policy_permissions = {
    LakeformationExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type = "AWS"
          identifiers = formatlist(
            "arn:aws:iam::%s:root",
            [
              local.environment_management.account_ids["analytical-platform-management-production"],
              local.environment_management.account_ids["analytical-platform-compute-development"]
          ])
        }
      ]
    }
  }

  tags = local.tags
}

module "analytical_platform_control_panel_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"


  trust_policy_permissions = {
    LakeformationExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type        = "AWS"
          identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[local.analytical_platform_environment])]
        }
      ]
    }
    ExplicitSelfRoleAssumption = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      condition = [{
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [format("arn:aws:iam::%s:role/%s", data.aws_caller_identity.current.account_id, "analytical-platform-control-panel")]
      }]
    }
  }

  name = "analytical-platform-control-panel"

  use_name_prefix = false
  policies = {
    lakeformation_share_policy = module.analytical_platform_lake_formation_share_policy.arn
    aws_lakeformation_policy   = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  }

  tags = local.tags
}

module "analytical_platform_data_eng_dba_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"


  trust_policy_permissions = {
    LakeformationExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type = "AWS"
          identifiers = formatlist(
            "arn:aws:iam::%s:root",
            [
              local.environment_management.account_ids[local.analytical_platform_environment],
              local.environment_management.account_ids["analytical-platform-management-production"]
          ])
        }
      ]
    }
  }
  name            = "analytical-platform-data-engineering-database-access"
  use_name_prefix = false
  policies = {
    lakeformation_share_policy = module.analytical_platform_lake_formation_share_policy.arn
    aws_lakeformation_policy   = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  }

  tags = local.tags
}

module "lake_formation_to_data_production_mojap_derived_tables_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "lake-formation-data-production-data-access"
  use_name_prefix = false
  policies = {
    mojap_derived_bucket_lake_formation_policy = module.data_production_mojap_derived_bucket_lake_formation_policy.arn
  }


  trust_policy_permissions = {
    LakeformationExecutionRole = {
      actions = ["sts:AssumeRole", "sts:SetContext"]
      principals = [
        {
          type = "Service"
          identifiers = [
            "glue.amazonaws.com",
            "lakeformation.amazonaws.com"
          ]
        }
      ]
    }
  }
  tags = local.tags
}

module "copy_apdp_cadet_metadata_to_compute_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  trust_policy_permissions = {
    LakeformationExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.eks_sso_access_role.names)}",
          ]
        }
      ]
    }
  }

  name            = "copy-apdp-cadet-metadata-to-compute"
  use_name_prefix = false

  policies = {
    copy_apdp_cadet_metadata_to_compute_policy = module.copy_apdp_cadet_metadata_to_compute_policy.arn
  }

  tags = local.tags
}
