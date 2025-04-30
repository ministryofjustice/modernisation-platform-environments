module "datadog-aws-config" {
  source                       = "DataDog/config-changes-datadog/aws"
  version                      = "1.0.0"
  dd_api_key_secret_arn        =  aws_secretsmanager_secret.datadog_api.arn
  dd_integration_role_name     = "datadog-awsconfig-integration-role"
  dd_destination_url           = "https://cloudplatform-intake.datadoghq.eu/api/v2/cloudchanges?dd-protocol=aws-kinesis-firehose"
  sns_topic_name               = "aws-config-topic"
  s3_bucket_name               = "awsconfig"
  failed_events_s3_bucket_name = "awsconfig-failed-events"
  tags = {
    "team" = "AWS"
  }
}