data "aws_iam_policy_document" "lambda_invoke_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "${aws_lambda_function.get_metadata_from_rds.arn}:*",
      "${aws_lambda_function.create_athena_external_table.arn}:*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      aws_lambda_function.get_metadata_from_rds.arn,
      aws_lambda_function.create_athena_external_table.arn,
    ]
  }
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
    actions = ["sts:AssumeRole"]
    principals {
        type = "Service"
        identifiers = ["states.amazon.com"]
    }
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
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_invoke_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_xray_policy" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.xray_policy.arn
}