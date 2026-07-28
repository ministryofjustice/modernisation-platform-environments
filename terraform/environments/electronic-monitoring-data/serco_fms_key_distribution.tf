# ------------------------------------------------------------------------------
# Serco FMS credential-distribution configuration
# ------------------------------------------------------------------------------

locals {
  # Enable the workflow in development only while the end-to-end integration
  # is tested. Other environments remain disabled.
  serco_fms_key_distribution_enabled = local.is-development

  serco_fms_notify_email_template_id = "f547eba8-a5d4-4218-b5ff-a238bc054136"

  serco_fms_notify_ack_sms_template_id = "6ac304b0-bc7e-43f6-a192-826345d8bd17"

  serco_fms_notify_password_sms_template_id = "ee1ee19f-7cf9-45ac-97a8-eb4c8c3ff7fd"

  serco_fms_acknowledgement_schedule_expression = "rate(5 minutes)"

  serco_fms_acknowledgement_ttl_hours = 24

  serco_fms_notify_file_retention_period = "1 week"

  serco_fms_key_distribution_bucket_prefix = "${local.bucket_prefix}-serco-fms-keys-"

  serco_fms_key_distribution_files_prefix = "files"

  serco_fms_key_distribution_passwords_prefix = "passwords"

  serco_fms_key_distribution_state_prefix = "state"

  serco_fms_key_distribution_events_prefix = "events"

  # ---------------------------------------------------------------------------
  # Credential secrets included in one distribution batch
  # ---------------------------------------------------------------------------

  serco_fms_key_distribution_secret_specs = [
    {
      label = "General"

      secret_arn = module.s3-fms-general-landing-bucket-iam-user.secret_arn
    },
    {
      label = "Home Office"

      secret_arn = module.s3-fms-ho-landing-bucket-iam-user.secret_arn
    },
    {
      label = "Specials"

      secret_arn = module.s3-fms-specials-landing-bucket-iam-user.secret_arn
    },
  ]

  serco_fms_key_distribution_feed_secret_arns = [
    for specification in local.serco_fms_key_distribution_secret_specs :
    specification.secret_arn
  ]
}


# ------------------------------------------------------------------------------
# Distribution encryption key
#
# This key protects:
# - the distribution S3 bucket;
# - the temporary PDF-password ciphertext;
# - the recipient-configuration secret;
# - the GOV.UK Notify API-key secret.
# ------------------------------------------------------------------------------

resource "aws_kms_key" "serco_fms_key_distribution" {
  description = "Encrypts Serco FMS distribution artifacts and configuration"

  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(
    local.tags,
    {
      resource-type = "serco-fms-key-distribution"
      purpose       = "serco-fms-key-distribution-encryption"
    },
  )
}

resource "aws_kms_alias" "serco_fms_key_distribution" {
  name = "alias/serco-fms-key-distribution-${local.environment_shorthand}"

  target_key_id = aws_kms_key.serco_fms_key_distribution.key_id
}


# ------------------------------------------------------------------------------
# Approved Notify recipient configuration
#
# Terraform creates only the secret container. Approved contact values are
# inserted manually after apply so they never enter Terraform state.
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "serco_fms_recipient_configuration" {
  #checkov:skip=CKV_AWS_66:Contact configuration is manually versioned and is not a rotatable credential.

  name = "serco-fms-notify-recipients-${local.environment_shorthand}"

  description = "Approved email and SMS recipients for Serco FMS key distribution"

  kms_key_id = aws_kms_key.serco_fms_key_distribution.arn

  recovery_window_in_days = 30

  tags = merge(
    local.tags,
    {
      resource-type = "serco-fms-key-distribution"
      purpose       = "serco-fms-recipient-configuration"
    },
  )
}


# ------------------------------------------------------------------------------
# GOV.UK Notify API key
#
# Terraform creates only the secret container. The API key is inserted manually
# after apply so it never enters Terraform state.
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "serco_fms_notify_api_key" {
  #checkov:skip=CKV_AWS_66:GOV.UK Notify API keys are rotated manually because AWS automatic rotation is not supported.

  name = "serco-fms-notify-api-key-${local.environment_shorthand}"

  description = "GOV.UK Notify API key for Serco FMS key distribution"

  kms_key_id = aws_kms_key.serco_fms_key_distribution.arn

  recovery_window_in_days = 30

  tags = merge(
    local.tags,
    {
      resource-type = "serco-fms-key-distribution"
      purpose       = "serco-fms-notify-api-key"
    },
  )
}