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
