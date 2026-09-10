resource "aws_security_group" "seed_lambda" {
  name_prefix = "${var.name}-seed-"
  description = "Security group for the DMS integration-test database seed Lambda."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-seed"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "seed_lambda" {
  security_group_id = aws_security_group.seed_lambda.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_seed_lambda" {
  security_group_id = aws_security_group.postgres.id

  referenced_security_group_id = aws_security_group.seed_lambda.id

  from_port   = var.postgres_port
  to_port     = var.postgres_port
  ip_protocol = "tcp"

  description = "Allow the database seed Lambda to connect to PostgreSQL."
}

data "aws_iam_policy_document" "seed_lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "seed_lambda" {
  name_prefix        = "dms-core-seed-"
  assume_role_policy = data.aws_iam_policy_document.seed_lambda_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "seed_lambda_basic_execution" {
  role       = aws_iam_role.seed_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "seed_lambda_vpc_access" {
  role       = aws_iam_role.seed_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "seed_lambda" {
  statement {
    sid = "ReadRdsSecret"

    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_db_instance.postgres.master_user_secret[0].secret_arn,
    ]
  }

  statement {
    sid = "DecryptRdsSecret"

    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }
}

resource "aws_iam_role_policy" "seed_lambda" {
  name   = "database-seed"
  role   = aws_iam_role.seed_lambda.id
  policy = data.aws_iam_policy_document.seed_lambda.json
}

resource "aws_lambda_function" "seed" {
  # checkov:skip=CKV_AWS_50:Temporary integration-test Lambda does not require X-Ray tracing.
  # checkov:skip=CKV_AWS_116:Lambda is invoked synchronously during integration testing and does not require a DLQ.
  # checkov:skip=CKV_AWS_272:Code signing is not required for this temporary integration-test Lambda.

  function_name = "${var.name}-seed"

  role         = aws_iam_role.seed_lambda.arn
  package_type = "Image"
  image_uri    = var.seed_image_uri

  architectures = [
    "arm64",
  ]

  timeout     = 30
  memory_size = 256

  kms_key_arn = var.kms_key_arn

  reserved_concurrent_executions = 1

  vpc_config {
    subnet_ids = var.subnet_ids

    security_group_ids = [
      aws_security_group.seed_lambda.id,
    ]
  }

  environment {
    variables = {
      RDS_SECRET_ARN = aws_db_instance.postgres.master_user_secret[0].secret_arn
      DB_HOST        = aws_db_instance.postgres.address
      DB_PORT        = tostring(aws_db_instance.postgres.port)
      DB_NAME        = aws_db_instance.postgres.db_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.seed_lambda_basic_execution,
    aws_iam_role_policy_attachment.seed_lambda_vpc_access,
    aws_iam_role_policy.seed_lambda,
    aws_vpc_security_group_ingress_rule.postgres_from_seed_lambda,
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-seed"
      Purpose = "DMS integration-test database seeding"
    }
  )
}
