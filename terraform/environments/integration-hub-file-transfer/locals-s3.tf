locals {
  s3_enabled_environments = [
    "development",
    "production",
  ]

  create_s3_buckets = contains(local.s3_enabled_environments, local.environment)

  s3_bucket_keys = [
    "incoming",
    "processing",
    "clean",
    "quarantine",
    "investigation",
  ]

  s3_eventbridge_enabled = {
    incoming      = true
    processing    = true
    clean         = true
    quarantine    = true
    investigation = true
  }

  s3_default_lifecycle_days = {
    development = 1
    production  = 14
  }

  s3_default_lifecycle_rules = {
    for environment, days in local.s3_default_lifecycle_days : environment => [
      {
        id     = "expire-objects-after-${days}-days"
        status = "Enabled"
        filter = {}
        expiration = {
          days = days
        }
        abort_incomplete_multipart_upload = {
          days_after_initiation = days
        }
      }
    ]
  }

  # Add per-bucket overrides here for production prefix-specific rules when the prefixes are known.
  s3_lifecycle_rule_overrides = {
    development = {}
    production  = {}
  }

  s3_lifecycle_rules = {
    for bucket_key in local.s3_bucket_keys : bucket_key => try(
      local.s3_lifecycle_rule_overrides[local.environment][bucket_key],
      lookup(local.s3_default_lifecycle_rules, local.environment, []),
    )
  }

  s3_bucket_configuration = {
    for bucket_key in local.s3_bucket_keys : bucket_key => {
      bucket          = "${local.application_name}-${bucket_key}-${local.environment}"
      eventbridge     = local.s3_eventbridge_enabled[bucket_key]
      lifecycle_rules = local.s3_lifecycle_rules[bucket_key]
    }
    if local.create_s3_buckets
  }
}
