module "config_changes_datadog" {
  source  = "DataDog/config-changes-datadog/aws"
  version = "1.0.0"
  datadog_api_key_secret_arn = aws_secretsmanager_secret.datadog_api.arn
  dd_destination_url         = "https://cloudplatform-intake.datadoghq.eu/api/v2/cloudchanges?dd-protocol=aws-kinesis-firehose"

  # Optional: You can provide overrides if needed
  # sns_topic_name             = "my-config-topic"
  # iam_role_name              = "datadog-sns-role"
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = "aws-config-snapshot-bucket"
  sns_topic_arn  = module.config_changes_datadog.sns_topic_arn
}