resource "aws_athena_workgroup" "default" {
  name        = format("%s-default", local.env_account_id)
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.athena-s3-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824 # 1 GB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${module.athena-s3-bucket.bucket.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
  
  tags = merge(
    local.tags,
    {
      Resource_Type = "Athena Workgroup for default Query Result Location results, logs and query limits",
    }
  )
}
