module "elevenlabs_asr_sagemaker_execution_iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  name            = "${local.deployment_name}-sagemaker-execution-role"
  use_name_prefix = false

  trust_policy_permissions = {
    SageMakerAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["sagemaker.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    CloudWatchMetrics = {
      sid     = "CloudWatchMetrics"
      effect  = "Allow"
      actions = ["cloudwatch:PutMetricData"]
      # cloudwatch:PutMetricData does not support resource-level permissions
      resources = ["*"]
    }
    CloudWatchLogs = {
      sid    = "CloudWatchLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
      ]
      resources = [
        "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/Endpoints/${local.deployment_name}",
        "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/Endpoints/${local.deployment_name}:log-stream:*",
      ]
    }
    KMSAccess = {
      sid    = "KMSAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      resources = [module.elevenlabs_asr_kms_key[0].key_arn]
    }
  }
}

module "justice_transcribe_backend_iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  name            = "${local.deployment_name}-justice-transcribe-backend-execution-role"
  use_name_prefix = false

  trust_policy_permissions = {
    EntraAssumeRoleWithWebIdentity = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [{
        type        = "Federated"
        identifiers = [data.aws_iam_openid_connect_provider.justiceuk_entra[0].arn]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra_secret[0].secret_string)["tenant_id"]}/:aud"
          values   = [jsondecode(data.aws_secretsmanager_secret_version.justice_transcribe_backend_secret[0].secret_string)["audience"]]
        },
        {
          test     = "StringEquals"
          variable = "sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra_secret[0].secret_string)["tenant_id"]}/:sub"
          values   = [jsondecode(data.aws_secretsmanager_secret_version.justice_transcribe_backend_secret[0].secret_string)["subject"]]
        }
      ]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    InvokeElevenLabsEndpoint = {
      sid       = "InvokeElevenLabsEndpoint"
      effect    = "Allow"
      actions   = ["sagemaker:InvokeEndpoint"]
      resources = [aws_sagemaker_endpoint.elevenlabs_asr[0].arn]
    }
  }
}
