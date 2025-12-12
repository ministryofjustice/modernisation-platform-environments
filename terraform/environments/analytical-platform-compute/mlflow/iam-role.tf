module "mlflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "6.2.3"

  role_name_prefix = "mlflow"

  role_policy_arns = {
    MlflowPolicy = module.mlflow_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["${kubernetes_namespace.mlflow.metadata[0].name}:mlflow"]
    }
  }

  tags = local.tags
}
