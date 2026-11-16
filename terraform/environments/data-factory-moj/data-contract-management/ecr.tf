resource "aws_ecr_repository" "schema_registration" {
  count = local.contract_management_enabled ? 1 : 0

  name                 = "${local.registration_name}-registration"
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

data "aws_iam_policy_document" "registration_image_access" {
  count = local.contract_management_enabled ? 1 : 0

  statement {
    sid    = "AllowRegistrationLambdaImageRetrieval"
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
        "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${local.registration_name}",
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "schema_registration" {
  count = local.contract_management_enabled ? 1 : 0

  repository = aws_ecr_repository.schema_registration[0].name
  policy     = data.aws_iam_policy_document.registration_image_access[0].json
}
