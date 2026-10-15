locals {
  incoming_bucket_name = "integration-hub-file-transfer-${local.environment}-incoming"
  mft_account_id       = local.environment_management.account_ids["integration-hub-file-transfer-${local.environment}"]
}

# Resolve the full key ARN through the stable cross-account alias.
data "aws_kms_key" "incoming" {
  key_id = "arn:aws:kms:eu-west-2:${local.mft_account_id}:alias/s3/incoming"
}

module "integration_hub_file_transfer_api" {
  source = "../modules/file-transfer-api"

  environment = local.environment
  tags        = local.tags
  upload_bucket = {
    name        = local.incoming_bucket_name
    arn         = "arn:aws:s3:::${local.incoming_bucket_name}"
    kms_key_arn = data.aws_kms_key.incoming.arn
  }
}
