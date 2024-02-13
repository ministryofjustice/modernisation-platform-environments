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
#   statement {
#     sid = "S3ReadWrite"
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#     actions = [
#         "kms:Decrypt",
#         "kms:Encrypt",
#         "kms:GenerateDataKey",
#     ]
#     resources = [
#           Resource  = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
#     ]
#   }
}

# Need for transfer workflow?
# resource "aws_lambda_permission" "s3_invoke_lambda_permission" {
#   statement_id  = "AllowExecutionFromS3"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.checksum_lambda_function.arn
#   principal     = "s3.amazonaws.com"
#   source_arn    = "${aws_s3_bucket.s3_bucket.arn}"
#   source_account = data.aws_caller_identity.current.account_id
# }

# resource "aws_iam_role" "s3_batch_role" {
#   name               = "S3BatchRole"
#   assume_role_policy = data.aws_iam_policy_document.this.json
# }

# data "aws_iam_policy_document" "this" {
#   statement {
#     sid = "S3ReadWrite"
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["batchoperations.s3.amazonaws.com"]
#     }

#     actions = [
#         "s3:PutObject",
#         "s3:PutObjectAcl",
#         "s3:PutObjectTagging",
#         "s3:GetObject",
#         "s3:GetObjectVersion",
#         "s3:GetObjectAcl",
#         "s3:GetObjectTagging",
#         "s3:ListBucket",
#         "s3:InitiateReplication",
#         "s3:GetReplicationConfiguration",
#         "s3:PutInventoryConfiguration",
#     ]
#     resources = [
#       "${aws_s3_bucket.THE BUCKET.arn}/*"
#     ]
#   }
#   statement {
#     sid = "S3ReadWrite"
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["batchoperations.s3.amazonaws.com"]
#     }
#     actions = [
#         "kms:Decrypt",
#         "kms:Encrypt",
#         "kms:GenerateDataKey",
#     ]
#     resources = [
#           Resource  = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
#     ]

#   }
# }

# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket" "s3_bucket" {
#   bucket = var.s3_bucket
# }
