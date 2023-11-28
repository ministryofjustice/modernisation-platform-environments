data "aws_eks_cluster" "apps_and_tools" {
  name = "apps-tools-${local.environment}"
}

data "aws_iam_openid_connect_provider" "apps_and_tools" {
  url = data.aws_eks_cluster.apps_and_tools.identity[0].oidc[0].issuer
}

module "datahub_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "datahub"

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.apps_and_tools.arn
      namespace_service_accounts = ["datahub:datahub-datahub-frontend"]
    }
  }
}