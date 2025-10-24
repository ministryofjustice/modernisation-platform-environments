# IAM Role and Policy for Scheduler to invoke Step Function
resource "aws_iam_role" "scheduler_invoke_sfn_role" {
  name = "scheduler-invoke-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-scheduler-invoke-cwa-sfn-role"
    }
  )
}

resource "aws_iam_policy" "scheduler_invoke_sfn" {
  name = "scheduler-invoke-sfn-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "states:StartExecution",
      Resource = "${aws_sfn_state_machine.sfn_state_machine.arn}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_sfn_attachment" {
  role       = aws_iam_role.scheduler_invoke_sfn_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_sfn.arn
}

# IAM Role and Policy for Scheduler to invoke Lambda Functions
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-provider-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-scheduler-invoke-provider-functions-role"
    }
  )
}

resource "aws_iam_policy" "scheduler_invoke_lambda" {
  name = "scheduler-invoke-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = [
        aws_lambda_function.ccms_provider_load.arn,
        aws_lambda_function.maat_provider_load.arn,
        aws_lambda_function.ccr_provider_load.arn,
        aws_lambda_function.cclf_provider_load.arn,
        aws_lambda_function.purge_lambda.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_lambda_attachment" {
  role       = aws_iam_role.scheduler_invoke_lambda_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}




