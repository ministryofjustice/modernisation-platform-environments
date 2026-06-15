resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_sftp_access_logs"
  bucket = data.aws_s3_bucket.logging_bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = lower(format("%s-lb-access-logs", local.sftp_env_suffix))

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${data.aws_s3_bucket.logging_bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

# SQL query to creates the table in the athena db, these queries needs to be executed manually after creation
resource "aws_athena_named_query" "main_table_sftp_internal_query" {
  name      = lower(format("%s-create-table", local.sftp_env_suffix))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_internal_table.sql",
    {
      bucket     = data.aws_s3_bucket.logging_bucket.id
      key        = "${local.sftp_suffix}-lb"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP, these queries needs to be executed manually after creation
resource "aws_athena_named_query" "http_requests_sftp_internal_query" {
  name      = lower(format("%s-http-get-requests", local.sftp_env_suffix))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_internal_http_gets.sql",
    {
      bucket     = data.aws_s3_bucket.logging_bucket.id
      key        = "${local.sftp_suffix}-lb"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}
