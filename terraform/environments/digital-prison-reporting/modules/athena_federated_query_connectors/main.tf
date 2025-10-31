# tflint-ignore-file: terraform_required_version, terraform_required_providers

locals {
  default_connection = { "default" = values(var.connection_strings)[0] }
  # Transform connection_strings to the format required by the connector environment properties and add a default
  connection_strings = merge({ for k, v in var.connection_strings : "${k}_connection_string" => v }, local.default_connection)
  is_oracle          = var.athena_connector_type == "oracle"
  is_postgresql      = var.athena_connector_type == "postgresql"
  is_redshift        = var.athena_connector_type == "redshift"
}

resource "aws_security_group" "athena_federated_query_lambda_sg_oracle" {
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  count       = local.is_oracle ? 1 : 0
  name_prefix = "${var.name}-lambda-security-group-oracle"
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
    description = "Allow connections to Oracle, BODMIS"
    from_port   = 1522
    to_port     = 1522
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

resource "aws_security_group" "athena_federated_query_lambda_sg_postgresql" {
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  count       = local.is_postgresql ? 1 : 0
  name_prefix = "${var.name}-lambda-security-group-postgresql"
  description = "Athena Federated Query PostgreSQL Lambda Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  egress {
    description = "Allow connections to Postgresql"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_security_group" "athena_federated_query_lambda_sg_redshift" {
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  count       = local.is_redshift ? 1 : 0
  name_prefix = "${var.name}-lambda-security-group-redshift"
  description = "Athena Federated Query Redshift Lambda Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  egress {
    description = "Allow connections to Redshift"
    from_port   = 5439
    to_port     = 5439
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

resource "aws_lambda_function" "athena_federated_query_lambda" {
  #checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #checkov:skip=CKV_AWS_272:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083


  function_name                  = "${var.name}-function"
  role                           = aws_iam_role.athena_federated_query_lambda_execution_role.arn
  handler                        = var.lambda_handler
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
    security_group_ids = local.is_oracle ? [
      aws_security_group.athena_federated_query_lambda_sg_oracle[0].id
      ] : local.is_postgresql ? [
      aws_security_group.athena_federated_query_lambda_sg_postgresql[0].id
    ] : [aws_security_group.athena_federated_query_lambda_sg_redshift[0].id]

    subnet_ids = [
      var.subnet_id
    ]
  }

  environment {
    variables = merge({
      spill_bucket = var.spill_bucket_name
      spill_prefix = var.spill_bucket_prefix
    }, local.connection_strings)
  }
}
