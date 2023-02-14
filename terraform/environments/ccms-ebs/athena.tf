resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket = module.s3-bucket-logging.bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = lower(format("%s-%s-lb-access-logs", local.application_name, local.environment))

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-bucket-logging.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "main_table" {
  name      = lower(format("%s-%s-create-table", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}