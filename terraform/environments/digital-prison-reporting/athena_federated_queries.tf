locals {
  spill_bucket_name               = module.s3_working_bucket.bucket_id
  oracle_connector_jar_bucket_key = "third-party/athena-connectors/athena-oracle-2024.18.2.jar"
  connection_string_nomis         = "oracle://jdbc:oracle:thin:$${external/dpr-nomis-source-secrets-for-athena-federated-query}@10.26.24.136:1521:CNOMT3"
}

resource "aws_iam_policy" "athena_federated_query_connector_policy" {
  name        = "athena_federated_query_connector_policy"
  description = "The policy the connector will use"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${local.account_region}:${local.account_id}:*"
        ]
      },
      {
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:ListSchemas",
          "dynamodb:ListTables",
          "dynamodb:Query",
          "dynamodb:Scan",
          "glue:GetTableVersions",
          "glue:GetPartitions",
          "glue:GetTables",
          "glue:GetTableVersion",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetPartition",
          "glue:GetDatabase",
          "athena:GetQueryExecution",
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${local.spill_bucket_name}",
          "arn:aws:s3:::${local.spill_bucket_name}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : [
          "arn:aws:secretsmanager:${local.account_region}:${local.account_id}:secret:external/dpr-nomis-source-secrets-for-athena-federated-query"
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "athena_federated_query_lambda_execution_role" {

  name        = "AthenaFederatedQueryLambdaExecutionRole"
  description = "Lambda will assume this role to run the connector"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" :
        {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "athena_federated_query_lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.athena_federated_query_connector_policy.arn
  role       = aws_iam_role.athena_federated_query_lambda_execution_role.name
}

resource "aws_security_group" "athena_federated_query_lambda_sg" {
  name_prefix = "athena-federated-query-lambda-sg"
  description = "Athena Federated Query Oracle Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

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
}

resource "aws_lambda_function" "athena_federated_query_oracle_lambda" {
  function_name = "AthenaFederatedQueryOracleLambda"
  role          = aws_iam_role.athena_federated_query_lambda_execution_role.arn
  handler       = "com.amazonaws.athena.connectors.oracle.OracleMuxCompositeHandler"
  runtime       = "java11"
  memory_size   = 3008
  timeout       = 900
  s3_bucket     = module.s3_artifacts_store.bucket_id
  s3_key        = local.oracle_connector_jar_bucket_key

  vpc_config {
    security_group_ids = [
      aws_security_group.athena_federated_query_lambda_sg.id
    ]

    subnet_ids = [
      data.aws_subnet.private_subnets_a.id
    ]
  }

  environment {
    variables = {
      nomis_connection_string = local.connection_string_nomis
      default                 = local.connection_string_nomis
      spill_bucket            = module.s3_working_bucket.bucket_id
      spill_prefix            = "athena-spill"
    }
  }
}

resource "aws_athena_data_catalog" "nomis_catalog" {
  name        = "nomis-catalog"
  description = "NOMIS Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = aws_lambda_function.athena_federated_query_oracle_lambda.arn
  }
}