locals {
  deployment_name = "elevenlabs-asr"
  elevenlabs_config = terraform.workspace == "data-platform-development" ? jsondecode(data.aws_secretsmanager_secret_version.elevenlabs_configuration_secret[0].secret_string) : {
    model_name        = ""
    model_package_arn = ""
    instance_type     = ""
  }
}

module "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.1

  name = "${local.component_name}/elevenlabs-configuration"

  secret_string = jsonencode({
    model_name        = "CHANGEME"
    model_package_arn = "CHANGEME"
    instance_type     = "CHANGEME"
  })
  ignore_secret_changes = true
}

data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

# ------------------------------------------------------------------------------
# KMS
# ------------------------------------------------------------------------------

module "elevenlabs_asr_kms_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases                 = ["${local.component_name}/${local.deployment_name}"]
  description             = "KMS key for ElevenLabs ASR SageMaker endpoint"
  enable_default_policy   = true
  deletion_window_in_days = 7

  key_users = [module.elevenlabs_asr_sagemaker_execution_iam_role[0].arn]
}

# ------------------------------------------------------------------------------
# IAM
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# SageMaker
# ------------------------------------------------------------------------------

resource "aws_sagemaker_model" "elevenlabs_asr" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  name                     = local.elevenlabs_config["model_name"]
  execution_role_arn       = module.elevenlabs_asr_sagemaker_execution_iam_role[0].arn
  enable_network_isolation = true

  primary_container {
    model_package_name = local.elevenlabs_config["model_package_arn"]
  }
}

resource "aws_sagemaker_endpoint_configuration" "elevenlabs_asr" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  name_prefix = "${local.deployment_name}-"
  kms_key_arn = module.elevenlabs_asr_kms_key[0].key_arn

  production_variants {
    variant_name           = "variant-1"
    model_name             = aws_sagemaker_model.elevenlabs_asr[0].name
    initial_instance_count = 1
    instance_type          = local.elevenlabs_config["instance_type"]
  }

  lifecycle {
    replace_triggered_by  = [aws_sagemaker_model.elevenlabs_asr]
    create_before_destroy = true
  }
}

resource "aws_sagemaker_endpoint" "elevenlabs_asr" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  name                 = local.deployment_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.elevenlabs_asr[0].name
}
