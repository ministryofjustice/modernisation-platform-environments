module "github_backup_function" {
  count = local.is_production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=b842374147fc07731d79028517223e9e0cbaab6d" # v8.8.0

  function_name = local.component_name
  description   = "Backs up GitHub repositories that opt in with the backup custom property"
  handler       = "main.handler"
  # Must match the Python version on the CI runner, which installs requirements.txt.
  runtime = "python3.12"

  # Each repository is backed up in its own invocation, so size for the largest repository.
  timeout                = 900
  memory_size            = 2048
  ephemeral_storage_size = 10240

  # Limits parallel clones; throttled async invocations are retried by Lambda.
  reserved_concurrent_executions = 5

  source_path = [{
    path             = "${path.module}/repository-backup-lambda"
    pip_requirements = true
    patterns = [
      "!tests/.*",
      "!(.*/)?__pycache__/.*",
    ]
  }]
  trigger_on_package_timestamp = false

  environment_variables = {
    GITHUB_ORGANISATION   = local.github_backup_organisation
    GITHUB_APP_SECRET_ARN = module.github_app_secret[0].secret_arn
    BACKUP_BUCKET         = module.github_backup_bucket[0].s3_bucket_id
  }

  create_async_event_config = true
  maximum_retry_attempts    = 1

  attach_policy_statements = true
  policy_statements = {
    github_app_secret_read = {
      sid       = "GitHubAppSecretRead"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.github_app_secret[0].secret_arn]
    }
    github_backup_upload = {
      sid    = "GitHubBackupUpload"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:AbortMultipartUpload"
      ]
      resources = ["${module.github_backup_bucket[0].s3_bucket_arn}/*"]
    }
    github_backup_encryption = {
      sid    = "GitHubBackupEncryption"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = [module.github_backup_key[0].key_arn]
    }
    # Built from the name to avoid a dependency cycle on the function's own ARN.
    github_backup_dispatch = {
      sid       = "GitHubBackupDispatch"
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = ["arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${local.component_name}"]
    }
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    schedule = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.github_backup_schedule[0].arn
    }
  }

  cloudwatch_logs_retention_in_days = 400

  tags = local.tags
}
