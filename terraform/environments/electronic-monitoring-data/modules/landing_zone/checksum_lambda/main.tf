resource "aws_lambda_function" "this" {
  filename         = "${path.module}/checksum_lambda.py"
  function_name    = "ChecksumLambda"
  role             = aws_iam_role.this.arn
  handler          = "checksum_lambda.handler"
  runtime          = "python3.9"
  timeout          = 900
}

resource "aws_iam_role" "this" {
  name               = "ChecksumLambdaRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  assume_role_policy  = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "S3ReadWrite"
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
        "s3:PutObjectTagging",
        "s3:GetObject",
        "s3:ListBucket",
    ]
    resources = [
      "${var.data_store_bucket.arn}/*"
    ]
  }
}
