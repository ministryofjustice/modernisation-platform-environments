data "aws_cloudwatch_event_bus" "file_transfer" {
  name = local.parent_event_bus_name
}

data "aws_s3_bucket" "clean" {
  bucket = local.clean_bucket_name
}

data "aws_kms_key" "clean" {
  key_id = local.clean_kms_key_alias
}

data "aws_kms_key" "secrets" {
  key_id = local.secrets_kms_key_alias
}

data "aws_kms_key" "logs" {
  key_id = local.logs_kms_key_alias
}

data "aws_secretsmanager_secret" "file_dispatch" {
  for_each = local.hosted_pickup_secret_names

  name = each.value
}