locals {
  deployment_name = "elevenlabs-asr"
  elevenlabs_config = terraform.workspace == "data-platform-development" ? jsondecode(data.aws_secretsmanager_secret_version.elevenlabs_configuration_secret[0].secret_string) : {
    model_name        = "placeholder"
    model_package_arn = "arn:aws:sagemaker:eu-west-2:000000000000:model-package/placeholder"
    instance_type     = "ml.m5.large"
  }
}
