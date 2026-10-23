# Oracle setup Lambda networking

resource "aws_security_group" "seed_lambda" {
  name_prefix = "${var.name}-oracle-seed-"
  description = "Security group for the Oracle DMS integration-test setup Lambda."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-oracle-seed"
      Purpose = "Oracle DMS integration-test database setup"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "seed_lambda" {
  security_group_id = aws_security_group.seed_lambda.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow the Oracle setup Lambda outbound access."
}

resource "aws_vpc_security_group_ingress_rule" "oracle_from_seed_lambda" {
  security_group_id = aws_security_group.oracle.id

  referenced_security_group_id = aws_security_group.seed_lambda.id

  from_port   = var.oracle_port
  to_port     = var.oracle_port
  ip_protocol = "tcp"

  description = "Allow the setup Lambda to connect to the Oracle source."
}

# Oracle setup Lambda IAM

data "aws_iam_policy_document" "seed_lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "seed_lambda" {
  name_prefix = "dms-oracle-seed-"

  assume_role_policy = data.aws_iam_policy_document.seed_lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-oracle-seed"
      Purpose = "Oracle DMS integration-test database setup"
    }
  )
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
    sid    = "ReadRDSMasterSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_db_instance.oracle.master_user_secret[0].secret_arn
    ]
  }

  statement {
    sid    = "ReadWriteDMSSourceSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.dms_source.arn
    ]
  }

  statement {
    sid    = "UseDMSSecretKMSKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "seed_lambda" {
  name_prefix = "dms-oracle-seed-"
  role        = aws_iam_role.seed_lambda.id
  policy      = data.aws_iam_policy_document.seed_lambda.json
}

# Oracle setup and mutation Lambda

resource "aws_lambda_function" "seed" {
  #checkov:skip=CKV_AWS_50: X-Ray tracing is unnecessary for this temporary development integration-test Lambda.
  #checkov:skip=CKV_AWS_116: The Lambda is invoked synchronously during integration testing and reports failures directly to its caller.
  #checkov:skip=CKV_AWS_272: Code signing is unnecessary for this temporary development integration-test Lambda.

  function_name = "${var.name}-oracle-seed"

  role         = aws_iam_role.seed_lambda.arn
  package_type = "Image"
  image_uri    = var.seed_image_uri

  architectures = [
    "x86_64"
  ]

  timeout     = 300
  memory_size = 512

  kms_key_arn = var.kms_key_arn

  reserved_concurrent_executions = 1

  vpc_config {
    subnet_ids = var.subnet_ids

    security_group_ids = [
      aws_security_group.seed_lambda.id
    ]
  }

  environment {
    variables = {
      RDS_SECRET_ARN          = aws_db_instance.oracle.master_user_secret[0].secret_arn
      DMS_SECRET_ARN          = aws_secretsmanager_secret.dms_source.arn
      DB_HOST                 = aws_db_instance.oracle.address
      DB_PORT                 = tostring(aws_db_instance.oracle.port)
      DB_NAME                 = aws_db_instance.oracle.db_name
      DMS_USERNAME            = upper(var.dms_username)
      ARCHIVE_RETENTION_HOURS = tostring(var.archive_log_retention_hours)
    }
  }

  depends_on = [
    aws_iam_role_policy.seed_lambda,
    aws_iam_role_policy_attachment.seed_lambda_basic_execution,
    aws_iam_role_policy_attachment.seed_lambda_vpc_access,
    aws_vpc_security_group_ingress_rule.oracle_from_seed_lambda
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-oracle-seed"
      Purpose = "Oracle DMS integration-test database setup and mutation"
    }
  )
}

resource "aws_lambda_invocation" "seed" {
  function_name   = aws_lambda_function.seed.function_name
  lifecycle_scope = "CREATE_ONLY"

  input = jsonencode({
    action = "seed"
  })

  triggers = {
    database_resource_id = aws_db_instance.oracle.resource_id
    image_uri            = var.seed_image_uri
  }

  depends_on = [
    aws_iam_role_policy.seed_lambda,
    aws_iam_role_policy_attachment.seed_lambda_basic_execution,
    aws_iam_role_policy_attachment.seed_lambda_vpc_access,
    aws_vpc_security_group_ingress_rule.oracle_from_seed_lambda
  ]
}