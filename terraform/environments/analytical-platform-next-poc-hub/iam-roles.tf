module "user_iam_roles" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = toset(local.users)

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  path            = "/users/"
  name            = each.key
  use_name_prefix = "false"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"]
      }]
    }
  }

  policies = {
    user_policy = module.user_iam_policies[each.key].arn
  }
}

module "project_iam_roles" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = toset(local.projects)

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  path            = "/projects/"
  name            = each.key
  use_name_prefix = "false"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"]
      }]
    }
  }

  policies = {
    user_policy = module.athena_access_policy.arn
  }
}


module "redshift_identity_centre_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  // Based on the policy from https://aws.amazon.com/blogs/big-data/integrate-identity-provider-idp-with-amazon-redshift-query-editor-v2-and-sql-client-using-aws-iam-identity-center-for-seamless-single-sign-on/

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name = "redshift-idc"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:SetContext"
      ]
      principals = [{
        type        = "Service"
        identifiers = ["redshift.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    IdentityCentreAccess = {
      effect = "Allow"
      actions = [
        "sso:DescribeApplication",
        "sso:DescribeInstance"
      ]
      resources = [
        local.identity_centre_instance,
        "arn:aws:sso::${local.environment_management.aws_organizations_root_account_id}:application/${local.identity_centre_instance_id}/*" // Leaving this as a wildcard for now
      ]
    }
    RedShiftAccess = {
      effect = "Allow"
      actions = [
        "redshift:DescribeQev2IdcApplications",
        "redshift-serverless:ListNamespaces",
        "redshift-serverless:ListWorkgroups",
        "redshift-serverless:GetWorkgroup"
      ]
      resources = ["*"]
    }
  }
}
