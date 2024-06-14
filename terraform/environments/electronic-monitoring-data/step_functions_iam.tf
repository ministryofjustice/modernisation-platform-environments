data "aws_iam_policy_document" "lambda_invoke_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${module.get_metadata_from_rds_lambda.lambda_function_arn}:*",
      "${module.create_athena_table.lambda_function_arn}:*",
      "${module.get_file_keys_for_table.lambda_function_arn}:*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      module.get_metadata_from_rds_lambda.lambda_function_arn,
      module.create_athena_table.lambda_function_arn,
      module.get_file_keys_for_table.lambda_function_arn,
    ]
  }
}


resource "aws_iam_policy" "step_function_kms_policy" {
  name        = "step-function-athena-layer-kms-policy"
  description = "Policy for Lambda to use KMS key for athena-layer step function"

  policy = data.aws_iam_policy_document.step_function_kms_policy.json
}

data "aws_iam_policy_document" "step_function_kms_policy" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.athena_layer_step_functions_log_key.arn]
  }
}

resource "aws_iam_role_policy_attachment" "step_function_kms_policy_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_function_kms_policy.arn
}


resource "aws_iam_policy" "step_function_log_policy" {
  name        = "step-function-athena-layer-log-policy"
  description = "Policy for Lambda to put logs for athena-layer step function"

  policy = data.aws_iam_policy_document.step_function_logs_policy.json
}


data "aws_iam_policy_document" "step_function_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "step_function_log_policy_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_function_log_policy.arn
}

data "aws_iam_policy_document" "xray_policy" {
  statement {
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "assume_step_functions" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "LambdaInvokePolicy"
  description = "Policy to allow invoking specific Lambda functions"
  policy      = data.aws_iam_policy_document.lambda_invoke_policy.json
}

resource "aws_iam_policy" "xray_policy" {
  name        = "XRayPolicy"
  description = "Policy to allow X-Ray actions"
  policy      = data.aws_iam_policy_document.xray_policy.json
}

resource "aws_iam_role" "step_functions_role" {
  name               = "StepFunctionsExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_step_functions.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_invoke_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_xray_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.xray_policy.arn
}


# --------------------------------
# Send database to AP
# -------------------------------- 
resource "aws_iam_role" "send_database_to_ap" {
  name               = "send_database_to_ap"
  assume_role_policy = data.aws_iam_policy_document.assume_step_functions.json
}

data "aws_iam_policy_document" "send_tables_to_ap_lambda_invoke_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${module.send_table_to_ap.lambda_function_arn}:*",
      "${module.get_tables_from_db.lambda_function_arn}:*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      module.send_table_to_ap.lambda_function_arn,
      module.get_tables_from_db.lambda_function_arn,
    ]
  }
}


resource "aws_iam_policy" "send_tables_to_ap_lambda_invoke_policy" {
  name        = "send_tables_to_ap_lambda_invoke_policy"
  description = "Policy to allow invoking specific Lambda functions"
  policy      = data.aws_iam_policy_document.send_tables_to_ap_lambda_invoke_policy.json
}

resource "aws_iam_role_policy_attachment" "send_to_database_attach_lambda_invoke_policy" {
  role       = aws_iam_role.send_database_to_ap.name
  policy_arn = aws_iam_policy.send_tables_to_ap_lambda_invoke_policy.arn
}

data "aws_iam_policy_document" "send_database_to_ap_kms_policy" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.send_database_to_ap_step_functions_log_key.arn]
  }
}

resource "aws_iam_policy" "send_database_to_ap_step_function_kms_policy" {
  name        = "send-database-to-ap-kms-policy"
  description = "Policy for Lambda to use KMS key for send_database_to_ap step function"

  policy = data.aws_iam_policy_document.send_database_to_ap_kms_policy.json
}


resource "aws_iam_role_policy_attachment" "send_to_database_step_function_kms_policy_policy_attachment" {
  role       = aws_iam_role.send_database_to_ap.name
  policy_arn = aws_iam_policy.send_database_to_ap_step_function_kms_policy.arn
}


resource "aws_iam_role_policy_attachment" "send_to_database_policy_attachment" {
  role       = aws_iam_role.send_database_to_ap.name
  policy_arn = aws_iam_policy.step_function_log_policy.arn
}


resource "aws_iam_role_policy_attachment" "send_to_database_x_ray_policy_attachment" {
  role       = aws_iam_role.send_database_to_ap.name
  policy_arn = aws_iam_policy.xray_policy.arn
}

