# ------------------------------------------------------------------------------
# Serco FMS secure key distribution configuration
# ------------------------------------------------------------------------------

locals {
  # Enable the workflow only in the development environment.
  serco_fms_key_distribution_enabled = local.is-development

  # The same GOV.UK Notify templates are used in each environment.
  # The environment is supplied as template personalisation.
  serco_fms_notify_email_template_id = (
    "f547eba8-a5d4-4218-b5ff-a238bc054136"
  )

  serco_fms_notify_sms_template_id = (
    "ee1ee19f-7cf9-45ac-97a8-eb4c8c3ff7fd"
  )

  # ---------------------------------------------------------------------------
  # Distribution-bucket configuration
  #
  # Keep this prefix unchanged. Changing it can replace the existing bucket.
  # ---------------------------------------------------------------------------

  serco_fms_key_distribution_bucket_prefix = (
    "${local.bucket_prefix}-serco-fms-keys-"
  )

  serco_fms_key_distribution_files_prefix = "files"

  serco_fms_key_distribution_passwords_prefix = "passwords"

  serco_fms_key_distribution_state_prefix = "state"

  serco_fms_key_distribution_events_prefix = "events"

  serco_fms_key_distribution_config_prefix = "config"

  serco_fms_key_distribution_allowlist_key = format(
    "%s/%s/allowlist.json",
    local.serco_fms_key_distribution_config_prefix,
    local.environment_shorthand,
  )

  # ---------------------------------------------------------------------------
  # Credential secrets distributed as one batch
  # ---------------------------------------------------------------------------

  serco_fms_key_distribution_secret_specs = [
    {
      label      = "General"
      secret_arn = module.s3-fms-general-landing-bucket-iam-user.secret_arn
    },
    {
      label      = "Home Office"
      secret_arn = module.s3-fms-ho-landing-bucket-iam-user.secret_arn
    },
    {
      label      = "Specials"
      secret_arn = module.s3-fms-specials-landing-bucket-iam-user.secret_arn
    },
  ]

  serco_fms_key_distribution_feed_secret_arns = [
    for specification in local.serco_fms_key_distribution_secret_specs :
    specification.secret_arn
  ]

  serco_fms_key_distribution_secret_arns = concat(
    local.serco_fms_key_distribution_feed_secret_arns,
    [
      aws_secretsmanager_secret.govuk_notify_serco_fms_api_key.arn,
    ],
  )

  # ---------------------------------------------------------------------------
  # FMS landing buckets observed after key rotation
  # ---------------------------------------------------------------------------

  serco_fms_landing_bucket_ids = [
    module.s3-fms-general-landing-bucket.bucket_id,
    module.s3-fms-ho-landing-bucket.bucket_id,
    module.s3-fms-specials-landing-bucket.bucket_id,
  ]

  serco_fms_landing_bucket_arns = [
    module.s3-fms-general-landing-bucket.bucket_arn,
    module.s3-fms-ho-landing-bucket.bucket_arn,
    module.s3-fms-specials-landing-bucket.bucket_arn,
  ]

  # ---------------------------------------------------------------------------
  # CloudTrail configuration for rotated-key adoption evidence
  # ---------------------------------------------------------------------------

  serco_fms_key_access_trail_name = format(
    "serco-fms-key-access-%s",
    local.environment_shorthand,
  )

  serco_fms_key_access_trail_log_prefix = (
    "cloudtrail/serco-fms-key-access"
  )

  serco_fms_key_access_trail_arn = format(
    "arn:aws:cloudtrail:%s:%s:trail/%s",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    local.serco_fms_key_access_trail_name,
  )
}


# ------------------------------------------------------------------------------
# GOV.UK Notify API key
#
# Keep the Terraform resource name and Secrets Manager name unchanged.
# The real API key is populated outside Terraform.
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "govuk_notify_serco_fms_api_key" {
  name = "govuk-notify-serco-fms-api-key"

  description = (
    "GOV.UK Notify API key for Serco FMS key distribution"
  )

  tags = merge(
    local.tags,
    {
      purpose = "serco-fms-key-distribution"
    },
  )
}

resource "aws_secretsmanager_secret_version" "govuk_notify_serco_fms_api_key" {
  secret_id = aws_secretsmanager_secret.govuk_notify_serco_fms_api_key.id

  # The real API key is inserted through the AWS CLI.
  secret_string = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}


# ------------------------------------------------------------------------------
# Temporary PDF-password encryption
# ------------------------------------------------------------------------------

resource "aws_kms_key" "serco_fms_key_distribution_passwords" {
  description = (
    "Encrypts temporary Serco FMS PDF password objects"
  )

  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(
    local.tags,
    {
      purpose = "serco-fms-key-distribution-passwords"
    },
  )
}

resource "aws_kms_alias" "serco_fms_key_distribution_passwords" {
  name = format(
    "alias/serco-fms-key-distribution-passwords-%s",
    local.environment_shorthand,
  )

  target_key_id = aws_kms_key.serco_fms_key_distribution_passwords.key_id
}