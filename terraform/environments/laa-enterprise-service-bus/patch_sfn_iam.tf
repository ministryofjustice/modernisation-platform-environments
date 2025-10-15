### Duplicate Infrastructure for CCMS Patch Testing ###

###############################
### Step Function IAM Resources ###
###############################
resource "aws_iam_role" "patch_step_function_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-patch-sfn-execution-role"

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
      Name = "${local.application_name_short}-patch-sfn-execution-role"
    }
  )
}


resource "aws_iam_policy" "patch_step_function_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "patch_sfn_invoke_lambdas"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.patch_cwa_extract_lambda[0].arn,
          aws_lambda_function.patch_cwa_file_transfer_lambda[0].arn,
          aws_lambda_function.patch_cwa_sns_lambda[0].arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_step_function_role_policy_attachment" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_step_function_role[0].name
  policy_arn = aws_iam_policy.patch_step_function_policy[0].arn
}