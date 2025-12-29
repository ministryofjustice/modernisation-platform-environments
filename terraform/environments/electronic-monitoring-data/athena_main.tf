resource "aws_athena_workgroup" "default" {
  name        = format("%s-default", local.env_account_id)
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}


resource "aws_athena_workgroup" "ears_sars" {
  name        = format("%s-ears-sars", local.env_account_id)
  description = "An Athena workgroup for EAR/SARs, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/ears_sars/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt" {
  name        = "create-a-derived-table"
  description = "An Athena workgroup for cadt, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt-historic-dev" {
  count = local.is-production ? 1 : 0
  name        = "create-a-derived-table-historic-dev"
  description = "An Athena workgroup for cadt historic dev, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/historic_dev/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

