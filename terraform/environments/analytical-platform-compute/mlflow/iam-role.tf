# Upgrading the IAM module from v5.x to v6.x introduces breaking changes that cause IAM roles and policies to be replaced. Therefore, we are not proceeding with the version upgrade.
module "mlflow_iam_role" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "6.6.1"

  role_name_prefix = "mlflow"

  role_policy_arns = {
    MlflowPolicy = module.mlflow_iam_policy[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["${kubernetes_namespace_v1.mlflow[0].metadata[0].name}:mlflow"]
    }
  }

  tags = local.tags
}
