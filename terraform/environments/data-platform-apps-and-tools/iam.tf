resource "aws_iam_policy" "datahub" {
  name        = "datahub-policy"
  path        = "/"
  description = "Datahub Policy for Data Ingestion"
  policy      = data.aws_iam_policy_document.datahub.json
}

module "datahub_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "datahub"
  role_policy_arns = {
    datahub-ingestion = aws_iam_policy.datahub.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.apps_and_tools.arn
      namespace_service_accounts = ["datahub:datahub-datahub-frontend"]
    }
  }
}