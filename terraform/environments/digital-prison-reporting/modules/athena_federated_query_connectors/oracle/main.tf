resource "aws_security_group" "athena_federated_query_lambda_sg" {
  name_prefix = "${var.project_prefix}-athena-federated-query-lambda-security-group"
  description = "Athena Federated Query Oracle Lambda Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  egress {
    description = "Allow connections to Oracle"
    from_port   = 1521
    to_port     = 1521
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow connections to Secrets Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "athena_federated_query_oracle_lambda" {
  function_name                  = "${var.project_prefix}-athena-federated-query-oracle-function"
  role                           = aws_iam_role.athena_federated_query_lambda_execution_role.arn
  handler                        = "com.amazonaws.athena.connectors.oracle.OracleMuxCompositeHandler"
  runtime                        = "java11"
  memory_size                    = var.lambda_memory_allocation_mb
  timeout                        = var.lambda_timeout_seconds
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions
  s3_bucket                      = var.connector_jar_bucket_name
  s3_key                         = var.connector_jar_bucket_key

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.athena_federated_query_lambda_sg.id
    ]

    subnet_ids = [
      var.subnet_id
    ]
  }

  environment {
    variables = {
      nomis_connection_string         = var.connection_string_nomis
      default                         = var.connection_string_nomis
      spill_bucket                    = var.spill_bucket_name
      spill_prefix                    = var.spill_bucket_prefix
      ATHENA_FEDERATION_SDK_LOG_LEVEL = var.connector_log_level
    }
  }
}
