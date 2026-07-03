locals {
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

  s3_bucket_lifecycle_defaults = {
    development = {
      default = [
        {
          id     = "expire-objects-after-1-day"
          status = "Enabled"
          filter = {}
          expiration = {
            days = 1
          }
          abort_incomplete_multipart_upload_days = 1
        },
      ]
    }

    production = {
      default = [
        {
          id     = "expire-objects-after-1-day"
          status = "Enabled"
          filter = {}
          expiration = {
            days = 14
          }
          abort_incomplete_multipart_upload_days = 1
        },
      ]
    }
  }

  s3_bucket_lifecycle_per_prefix = {
    development = {
      default = local.s3_bucket_lifecycle_defaults.development.default
      buckets = {}
    }

    production = {
      default = local.s3_bucket_lifecycle_defaults.production.default
      buckets = {
        incoming   = []
        processing = []
        clean = [
          {
            id     = "expire-clean-after-14-days"
            status = "Enabled"
            filter = {
              prefix = "clean/"
            }
            expiration = {
              days = 14
            }
          },
          {
            id     = "expire-example-after-3-days"
            status = "Enabled"
            filter = {
              prefix = "example/"
            }
            expiration = {
              days = 3
            }
          },
        ]

        quarantine    = []
        investigation = []
      }
    }
  }

  s3_lifecycle_rules = {
    for key in local.s3_bucket_keys : key =>
    try(
      local.s3_bucket_lifecycle_per_prefix[local.environment].buckets[key],
      local.s3_bucket_lifecycle_per_prefix[local.environment].default,
    )
  }

  s3_bucket_configuration = {
    for key in local.s3_bucket_keys : key => {
      bucket          = "${local.application_name}-${local.environment}-${key}"
      eventbridge     = local.s3_eventbridge_enabled[key]
      lifecycle_rules = local.s3_lifecycle_rules[key]
    }
  }
}
