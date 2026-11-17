# Process File From Bucket Lambda: picks up files in the BC inbound folder and posts them to the Financial Transfers API

module "process_file_lambda" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/7ec3b60
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/s3-lambda?ref=7ec3b60"

  name       = "${local.component_name}-${local.env_label}-process-file-from-bucket"
  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = data.aws_subnets.shared-private.ids

  # Placeholder package
  filename = "${path.module}/../../ccms-ebs/ccms-file-transfer/lambda/process_file_from_bucket/target/HelloWorldHandler-1.0.jar"
  handler  = "example.HelloWorldHandler"
  runtime  = "java25"

  environment_variables = {
    SECRET_NAME        = aws_secretsmanager_secret.process_file_lambda.arn
    BUCKET_BASE_PREFIX = local.bc_bucket_base_path
  }

  bucket_name = module.s3_bc_inbound.bucket.id
  trigger = {
    filter_prefix = "${local.bc_bucket_base_path}/inbound/"
  }

  secret_arns  = [aws_secretsmanager_secret.process_file_lambda.arn]
  kms_key_arns = [aws_kms_key.fin_transfer.arn]

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }

  tags = local.tags
}
