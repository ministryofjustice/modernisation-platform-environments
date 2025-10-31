# Step Functions execution role
resource "aws_iam_role" "step_function_role" {
  name = "${local.application_name_short}-sfn-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-sfn-execution-role"
    }
  )
}

# Inline policy to allow invoking your Lambdas
resource "aws_iam_policy" "step_function_policy" {
  name = "sfn_invoke_lambdas"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.cwa_extract_lambda.arn,
          aws_lambda_function.cwa_file_transfer_lambda.arn,
          aws_lambda_function.cwa_sns_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_role_policy_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}