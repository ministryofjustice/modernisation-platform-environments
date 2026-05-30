module "mlflow_iam_role" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.6.0"

  name            = "mlflow"
  use_name_prefix = false

  policies = {
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
