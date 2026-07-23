module "elevenlabs_asr_kms_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases                 = ["${local.component_name}/${local.deployment_name}"]
  description             = "KMS key for ElevenLabs ASR SageMaker endpoint"
  enable_default_policy   = true
  deletion_window_in_days = 7

  key_users = [module.elevenlabs_asr_sagemaker_execution_iam_role[0].arn]
}
