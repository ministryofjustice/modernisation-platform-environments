resource "aws_lambda_function" "test_ccms_provider_load" {
  description       = "Test connectivity to CCMS DB."
  function_name     = "test_ccms_provider_load_function"
  role              = aws_iam_role.ccms_provider_load_role.arn
  handler           = "lambda_function.lambda_handler"
  s3_bucket         = data.aws_s3_object.test_provider_load_zip.bucket
  s3_key            = data.aws_s3_object.test_provider_load_zip.key
  s3_object_version = data.aws_s3_object.test_provider_load_zip.version_id
  timeout           = 100
  memory_size       = 128
  runtime           = "python3.14"

  layers = [
    aws_lambda_layer_version.lambda_layer_p314_oic21.arn
  ]

  vpc_config {
    security_group_ids = [aws_security_group.ccms_provider_load.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      DB_SECRET_NAME         = aws_secretsmanager_secret.ccms_db_mp_credentials.name
      PROCEDURE_SECRET_NAME  = aws_secretsmanager_secret.ccms_procedures_config.name
      LD_LIBRARY_PATH        = "/opt/instantclient_21_23"
      ORACLE_HOME            = "/opt/instantclient_21_23"
      SERVICE_NAME           = "ccms-load-service"
      NAMESPACE              = "HUB20-CCMS-NS"
      ENVIRONMENT            = local.environment
      LOG_LEVEL              = "DEBUG"
      PURGE_LAMBDA_TIMESTAMP = aws_ssm_parameter.ccms_provider_load_timestamp.name
      TNS_ADMIN              = "/tmp/wallet_dir"
      WALLET_BUCKET          = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ             = "wallet_files/CCMS/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-ccms-provider-load" }
  )
}
