resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket     = module.s3-bucket.bucket.arn
#  bucket = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "main" {
  name     = lower(format("%s-%s-create-table", local.application_name, local.environment))
  database = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table.sql",
    {
      bucket     = module.s3-bucket.bucket.id
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = lower(format("%s-%s-lb-access-logs", local.application_name, local.environment))

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = module.s3-bucket.bucket.id != "" ? "s3://${module.s3-bucket.bucket.id}/output/" : "s3://${module.s3-bucket[0].bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}