locals {
	starter_pack_default_tags = {
		business-unit = "OCTO"
		application   = local.application_name
		is-production = local.is-production
		owner         = "container-platform"
		namespace     = "container-platform-terraform-starter-pack"

		environment-name       = local.environment
		infrastructure-support = "platforms@digital.justice.gov.uk"
	}
}

resource "aws_ecr_repository" "starter_pack" {
	count = local.environment == "development" ? 1 : 0

	name = "container-platform/container-platform-terraform-starter-pack"

	image_scanning_configuration {
		scan_on_push = true
	}

	force_delete = false
	tags         = local.starter_pack_default_tags

	lifecycle {
		ignore_changes = [name]
	}
}

data "aws_iam_policy_document" "starter_pack_ecr" {
	count   = local.environment == "development" ? 1 : 0
	version = "2012-10-17"

	statement {
		sid       = "AllowLogin"
		effect    = "Allow"
		actions   = ["ecr:GetAuthorizationToken"]
		resources = ["*"]
	}

	statement {
		sid    = "AllowPushPullListDelete"
		effect = "Allow"
		actions = [
			"ecr:BatchGetImage",
			"ecr:BatchCheckLayerAvailability",
			"ecr:BatchDeleteImage",
			"ecr:CompleteLayerUpload",
			"ecr:DescribeImages",
			"ecr:GetDownloadUrlForLayer",
			"ecr:InitiateLayerUpload",
			"ecr:ListImages",
			"ecr:PutImage",
			"ecr:UploadLayerPart"
		]
		resources = [aws_ecr_repository.starter_pack[0].arn]
	}
}

resource "aws_iam_policy" "starter_pack_ecr" {
	count = local.environment == "development" ? 1 : 0

	name   = "container-platform-ecr-starter-pack"
	policy = data.aws_iam_policy_document.starter_pack_ecr[0].json
	tags   = local.starter_pack_default_tags
}

data "aws_iam_openid_connect_provider" "github" {
	count = local.environment == "development" ? 1 : 0
	url   = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "starter_pack_github_oidc" {
	count   = local.environment == "development" ? 1 : 0
	version = "2012-10-17"

	statement {
		effect  = "Allow"
		actions = ["sts:AssumeRoleWithWebIdentity"]

		principals {
			type        = "Federated"
			identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
		}

		condition {
			test     = "StringLike"
			variable = "token.actions.githubusercontent.com:sub"
			values   = ["repo:ministryofjustice/container-platform-terraform-starter-pack:*"]
		}

		condition {
			test     = "StringEquals"
			variable = "token.actions.githubusercontent.com:aud"
			values   = ["sts.amazonaws.com"]
		}
	}
}

resource "aws_iam_role" "starter_pack_github" {
	count = local.environment == "development" ? 1 : 0

	name               = "container-platform-ecr-starter-pack-github"
	assume_role_policy = data.aws_iam_policy_document.starter_pack_github_oidc[0].json
	tags               = local.starter_pack_default_tags
}

resource "aws_iam_role_policy_attachment" "starter_pack_github_ecr" {
	count = local.environment == "development" ? 1 : 0

	role       = aws_iam_role.starter_pack_github[0].name
	policy_arn = aws_iam_policy.starter_pack_ecr[0].arn
}

output "starter_pack_repository_url" {
	value = local.environment == "development" ? aws_ecr_repository.starter_pack[0].repository_url : null
}

output "starter_pack_ecr_role_to_assume" {
	value = local.environment == "development" ? aws_iam_role.starter_pack_github[0].arn : null
}
