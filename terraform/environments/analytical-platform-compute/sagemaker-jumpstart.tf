# image
# model id


resource "aws_iam_role" "sagemaker_execution_role" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  name  = "poc-sagemaker-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "terraform-inferences-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudwatch:PutMetricData",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        }
      ]
    })

  }

  tags = local.tags
}

module "sagemaker_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count   = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  bucket = "mojap-compute-sagemaker-jumpstart-${local.environment}"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.sagemaker_bucket_policy[0].json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.tags,
    { "backup" = "false" }
  )
}

data "aws_iam_policy_document" "sagemaker_bucket_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0 # Creates IAM role if not provided
  statement {
    sid     = "BroadS3Access"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}/*",
    "arn:aws:s3:::mojap-compute-sagemaker-jumpstart-${local.environment}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sagemaker_execution_role[0].arn]
    }
  }
}
