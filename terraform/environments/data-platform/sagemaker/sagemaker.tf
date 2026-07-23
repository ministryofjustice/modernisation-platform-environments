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
