# ------------------------------------------------------------------------------
# Serco FMS credential-distribution configuration
# ------------------------------------------------------------------------------

locals {
  # Keep the preparation Lambda disabled until the recipient secret is populated
  # and the Notify workflow is added.
  serco_fms_key_distribution_enabled = false

  serco_fms_key_distribution_bucket_prefix = (
    "${local.bucket_prefix}-serco-fms-keys-"
  )

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

      secret_arn = (
        module
        .s3-fms-general-landing-bucket-iam-user
        .secret_arn
      )
    },
    {
      label = "Home Office"

      secret_arn = (
        module
        .s3-fms-ho-landing-bucket-iam-user
        .secret_arn
      )
    },
    {
      label = "Specials"

      secret_arn = (
        module
        .s3-fms-specials-landing-bucket-iam-user
        .secret_arn
      )
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
# - the recipient-configuration secret.
# ------------------------------------------------------------------------------

resource "aws_kms_key" "serco_fms_key_distribution" {
  description = (
    "Encrypts Serco FMS distribution artifacts and configuration"
  )

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
  name = format(
    "alias/serco-fms-key-distribution-%s",
    local.environment_shorthand,
  )

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

  name = format(
    "serco-fms-notify-recipients-%s",
    local.environment_shorthand,
  )

  description = (
    "Approved email and SMS recipients for Serco FMS key distribution"
  )

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