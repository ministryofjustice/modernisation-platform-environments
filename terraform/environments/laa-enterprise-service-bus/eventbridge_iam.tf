resource "aws_iam_role" "scheduler_invoke_role" {
  name = "scheduler-invoke-cwa-extract-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-scheduler-invoke-cwa-extract-lambda-role"
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
      Resource = "${aws_lambda_function.cwa_extract.arn}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_lambda_attachment" {
  role       = aws_iam_role.scheduler_invoke_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}
