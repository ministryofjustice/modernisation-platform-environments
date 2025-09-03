resource "aws_iam_role" "state_machine" {
  # checkov:skip=CKV_AWS_61: See comment below
  name = "${var.name}-step-functions-database-export"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# State machine role needs to invoke Lambda
data "aws_iam_policy_document" "sfn_role" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [module.csv-to-parquet-export.lambda_function_arn]
  }
}
resource "aws_iam_role_policy" "sfn_role" {
  role   = aws_iam_role.state_machine.id
  policy = data.aws_iam_policy_document.sfn_role.json
}

# Lambda permission to allow SFN to call it
resource "aws_lambda_permission" "allow_sfn_invoke" {
  statement_id  = "AllowSFNInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.csv-to-parquet-export.lambda_function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.csv_to_parquet_export.arn
}
