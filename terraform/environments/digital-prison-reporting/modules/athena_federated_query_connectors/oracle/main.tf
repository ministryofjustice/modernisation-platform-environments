resource "aws_iam_policy" "athena_federated_query_connector_policy" {
  name        = "athena_federated_query_connector_policy"
  description = "The policy the connector will use"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "cloudwatch:PutMetricData"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.region}:${var.account_id}:*"
        ]
      },
      {
        "Action" : [
          "glue:GetTableVersions",
          "glue:GetPartitions",
          "glue:GetTables",
          "glue:GetTableVersion",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetPartition",
          "glue:GetDatabase"
        ],
        "Resource" : "arn:aws:glue:${var.region}:${var.account_id}:*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "athena:GetQueryExecution"
        ],
        "Resource" : "arn:aws:athena:${var.region}:${var.account_id}:*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "arn:aws:s3:::*",
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
          "arn:aws:s3:::${var.spill_bucket_name}",
          "arn:aws:s3:::${var.spill_bucket_name}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : [
          var.nomis_credentials_secret_arn
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "kms:GenerateDataKey"
        ],
        "Resource" : [
          "arn:aws:kms:*:${var.account_id}:key/*"
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
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
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
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  egress {
    description = "Allow connections to Oracle"
    from_port   = 1521
    to_port     = 1521
    protocol    = "TCP"
    cidr_blocks = ["${var.nomis_ip_address}/32"]
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
  function_name                  = "AthenaFederatedQueryOracleLambda"
  role                           = aws_iam_role.athena_federated_query_lambda_execution_role.arn
  handler                        = "com.amazonaws.athena.connectors.oracle.OracleMuxCompositeHandler"
  runtime                        = "java11"
  memory_size                    = 3008
  timeout                        = 900
  reserved_concurrent_executions = 20
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
      nomis_connection_string = var.connection_string_nomis
      default                 = var.connection_string_nomis
      spill_bucket            = var.spill_bucket_name
      spill_prefix            = var.spill_bucket_prefix
    }
  }
}
