module "ecr_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.52.2"

  name = "ecr-access"

  subjects = [
    "ministryofjustice/*",
    "moj-analytical-services/*"
  ]

  policies = {
    ecr_access = module.ecr_access_iam_policy.arn
  }

  tags = local.tags
}
