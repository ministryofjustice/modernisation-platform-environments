data "aws_iam_policy_document" "rotation_lambda_assume_role" {
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

resource "aws_iam_role" "rotation_lambda" {
  name_prefix = "dms-oracle-rotation-"

  assume_role_policy = data.aws_iam_policy_document.rotation_lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-oracle-rotation"
      Purpose = "Oracle DMS source credential rotation"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_basic_execution" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_vpc_access" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "rotation_lambda" {
  #checkov:skip=CKV_AWS_356: Secrets Manager GetRandomPassword does not support resource-level permissions.

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
    sid    = "ManageDMSSourceSecretVersions"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]

    resources = [
      aws_secretsmanager_secret.dms_source.arn
    ]
  }

  statement {
    sid    = "GenerateRotationPassword"
    effect = "Allow"

    actions = [
      "secretsmanager:GetRandomPassword"
    ]

    resources = ["*"]
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

resource "aws_iam_role_policy" "rotation_lambda" {
  #checkov:skip=CKV_AWS_355: Secrets Manager GetRandomPassword requires wildcard resource access; all other secret permissions are scoped.

  name_prefix = "dms-oracle-rotation-"
  role        = aws_iam_role.rotation_lambda.id
  policy      = data.aws_iam_policy_document.rotation_lambda.json
}

# Oracle DMS credential rotation Lambda

resource "aws_lambda_function" "rotation" {
  #checkov:skip=CKV_AWS_50: X-Ray tracing is unnecessary for this development integration-test rotation function.
  #checkov:skip=CKV_AWS_116: Secrets Manager retries failed rotation stages and the failures are recorded in CloudWatch Logs.
  #checkov:skip=CKV_AWS_272: Code signing is unnecessary for this temporary development integration-test Lambda.

  function_name = "${var.name}-oracle-rotation"

  role         = aws_iam_role.rotation_lambda.arn
  package_type = "Image"
  image_uri    = var.seed_image_uri

  image_config {
    command = [
      "rotation_function.lambda_handler"
    ]
  }

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
      RDS_SECRET_ARN = aws_db_instance.oracle.master_user_secret[0].secret_arn
      DMS_SECRET_ARN = aws_secretsmanager_secret.dms_source.arn
      DB_HOST        = aws_db_instance.oracle.address
      DB_PORT        = tostring(aws_db_instance.oracle.port)
      DB_NAME        = aws_db_instance.oracle.db_name
      DMS_USERNAME   = upper(var.dms_username)
    }
  }

  depends_on = [
    aws_iam_role_policy.rotation_lambda,
    aws_iam_role_policy_attachment.rotation_lambda_basic_execution,
    aws_iam_role_policy_attachment.rotation_lambda_vpc_access,
    aws_vpc_security_group_ingress_rule.oracle_from_seed_lambda
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-oracle-rotation"
      Purpose = "Oracle DMS source credential rotation"
    }
  )
}

resource "aws_lambda_permission" "allow_secrets_manager_rotation" {
  statement_id  = "AllowSecretsManagerRotation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.dms_source.arn
}
