data "aws_eks_cluster" "apps_and_tools" {
  name = "apps-tools-${local.environment}"
}

data "aws_iam_openid_connect_provider" "apps_and_tools" {
  url = data.aws_eks_cluster.apps_and_tools.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "datahub" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/${local.environment_configuration.datahub_role}", local.environment_configuration.datahub_target_accounts)
  }
}

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