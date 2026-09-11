# IAM role for the quarantine Lambda function.
# This role allows the Lambda function to read from the scanned bucket, write to the quarantine bucket, and log to CloudWatch.


resource "aws_iam_role" "quarantine_lambda" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "quarantine_lambda" {
  name = "${var.name}-policy"
  role = aws_iam_role.quarantine_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]

        Resource = [
          "${var.quarantine_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging"
        ]

        Resource = [
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]

        Resource = [
          var.s3_bucket_kms_key_arn,
          var.quarantine_kms_key_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.quarantine_dlq.arn
      },
      {
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]

        Resource = var.lambda_kms_key_arn
      }
    ]
  })
}

# Permission to write logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.quarantine_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}