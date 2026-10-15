resource "aws_ecr_repository" "schema_validation" {
  count = local.contract_management_enabled ? 1 : 0

  name                 = local.validation_name_prefix
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition = (
        data.aws_caller_identity.current.account_id ==
        local.environment_management.account_ids[terraform.workspace]
      )
      error_message = "The AWS deployment account must match the selected Terraform workspace."
    }
  }
}

data "aws_iam_policy_document" "validation_image_access" {
  count = local.contract_management_enabled ? 1 : 0

  statement {
    sid    = "AllowValidationLambdaImageRetrieval"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${local.validation_function_prefix}-*",
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "schema_validation" {
  count = local.contract_management_enabled ? 1 : 0

  repository = aws_ecr_repository.schema_validation[0].name
  policy     = data.aws_iam_policy_document.validation_image_access[0].json
}
