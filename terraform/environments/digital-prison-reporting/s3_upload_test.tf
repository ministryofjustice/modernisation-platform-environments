resource "aws_amplify_app" "s3_upload_test_app" {
  name       = "${local.project}-s3-upload-test-app"
  platform   = "WEB"
  repository = ""

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands: []
      artifacts:
        baseDirectory: /
        files:
          - '**/*'
      cache:
        paths: []
  EOT
}

module "s3_upload_test_bucket" {
  source           = "./modules/s3_bucket"
  create_s3        = local.setup_buckets
  name             = "${local.project}-upload-test-${local.env}"
  custom_kms_key   = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle = false

  tags = merge(
    local.all_tags,
    {
      name          = "${local.project}-upload-test-${local.env}"
      Resource_Type = "S3 Bucket"
      Jira          = "DPR2-1499"
    }
  )
}

resource "aws_cognito_user_pool" "upload_test_users" {
  name = "${local.project}-upload-test-users"
}

resource "aws_cognito_user_pool_client" "upload_test_client" {
  name         = "${local.project}-upload-test-client"
  user_pool_id = aws_cognito_user_pool.upload_test_users.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  supported_identity_providers = ["COGNITO"]
  callback_urls = [] // todo
}

resource "aws_cognito_identity_pool" "upload_test_identity" {
  identity_pool_name = "${local.project}-upload-test-identity"

  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.upload_test_client.id
    provider_name = aws_cognito_user_pool.upload_test_users.endpoint
  }
}

data "aws_iam_policy_document" "upload_test_authenticated_user_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "upload_test_authenticated_user_role" {
  name = "${local.project}-upload-test-authenticated-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated
        }
      }
    ]
  })
}