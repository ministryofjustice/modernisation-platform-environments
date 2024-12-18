module "ecr_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.48.0"

  name = "ecr-access"

  subjects = [
    "ministrofjustice/*",
    "moj-analytical-services/*"
  ]

  policies = {
    ecr = module.ecr_access_iam_policy.arn
  }
}
