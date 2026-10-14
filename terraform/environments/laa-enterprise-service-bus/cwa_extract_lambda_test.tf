resource "aws_lambda_function" "test_cwa_extract_lambda" {
  description       = "Test connectivity to CWA DB."
  function_name     = "test_cwa_extract_lambda"
  role              = aws_iam_role.cwa_extract_lambda_role.arn
  handler           = "lambda_function.lambda_handler"
  s3_bucket         = data.aws_s3_object.test_cwa_extract_zip.bucket
  s3_key            = data.aws_s3_object.test_cwa_extract_zip.key
  s3_object_version = data.aws_s3_object.test_cwa_extract_zip.version_id
  timeout           = 900
  memory_size       = 128
  runtime           = "python3.14"

  layers = [
    aws_lambda_layer_version.lambda_layer_p314_oic21.arn
  ]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract_new.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      LD_LIBRARY_PATH   = "/opt/instantclient_21_23"
      ORACLE_HOME       = "/opt/instantclient_21_23"
      SERVICE_NAME      = "cwa-extract-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = local.environment
      LOG_LEVEL         = "DEBUG"
      TNS_ADMIN         = "/tmp/wallet_dir"
      WALLET_BUCKET     = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ        = "wallet_files/CWA/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda" }
  )
}
