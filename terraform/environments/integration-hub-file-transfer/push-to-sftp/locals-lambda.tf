locals {
  pattern_name     = "${local.application_name}-${local.component_name}"
  lambda_role_name = local.pattern_name

  dlq_arns = { for name, queue in module.sqs_push_to_sftp_dlq : name => queue.queue_arn }

  # Use an x86 build container on CI, but install wheels for the ARM64 Lambda runtime.
  lambda_docker_additional_options = [
    "--platform", "linux/amd64",
    "-e", "PIP_PLATFORM=manylinux_2_34_aarch64 manylinux_2_28_aarch64 manylinux_2_17_aarch64 manylinux2014_aarch64",
    "-e", "PIP_ONLY_BINARY=:all:",
  ]

  lambda_source_path = [{
    path             = "${path.module}/lambda/push-to-sftp-writer"
    pip_requirements = true
    patterns = [
      "!([^/]+/)*(tests|__pycache__|\\.pytest_cache)(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

  lambda_environment_variables = {
    ACTION_NAME                     = "push-to-sftp"
    AUTHORISED_DESTINATION_MAP      = jsonencode(local.sftp_destinations_by_secret)
    CREDENTIAL_SECRET_MAP           = jsonencode(local.credential_arns_by_secret)
    DELIVERY_ROLE_MAP               = jsonencode(local.delivery_role_arns_by_secret)
    EVENT_BUS_NAME                  = data.aws_cloudwatch_event_bus.file_transfer.name
    IDEMPOTENCY_EXPIRY_SECONDS      = tostring(7 * 24 * 60 * 60)
    IDEMPOTENCY_TABLE               = module.dynamodb_idempotency.dynamodb_table_id
    POWERTOOLS_LOG_LEVEL            = "INFO"
    SOURCE_BUCKET                   = data.aws_s3_bucket.clean.id
    SOURCE_PREFIX_MAP               = jsonencode(local.source_prefixes_by_secret)
    SUPPORTED_REGION                = "eu-west-2"
    TERMINAL_OUTCOME_EXPIRY_SECONDS = tostring(7 * 24 * 60 * 60)
  }
}