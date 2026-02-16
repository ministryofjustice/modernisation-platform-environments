resource "aws_athena_database" "ssogen_lb-access-logs" {
  count  = local.is-development || local.is-test ? 1 : 0
  name   = "ssogen_loadbalancer_access_logs"
  bucket = module.s3-bucket-logging.bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_workgroup" "ssogen_lb-access-logs" {
  count = local.is-development || local.is-test ? 1 : 0
  name  = lower(format("%s-lb-access-logs", local.application_name_ssogen, local.environment))

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

# SQL query to creates the table in the athena db, these queries needs to be executed manually after creation
resource "aws_athena_named_query" "main_table_ssogen" {
  count     = local.is-development || local.is-test ? 1 : 0
  name      = lower(format("%s-%s-create-table", local.application_name_ssogen, local.environment))
  workgroup = aws_athena_workgroup.ssogen_lb-access-logs[count.index].id
  database  = aws_athena_database.ssogen_lb-access-logs[count.index].name
  query = templatefile(
    "./templates/create_internal_ssogen_table.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ssogen_internal
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP, these queries needs to be executed manually after creation
resource "aws_athena_named_query" "http_requests_ssogen" {
  count     = local.is-development || local.is-test ? 1 : 0
  name      = lower(format("%s-%s-http-get-requests", local.application_name_ssogen, local.environment))
  workgroup = aws_athena_workgroup.ssogen_lb-access-logs[count.index].id
  database  = aws_athena_database.ssogen_lb-access-logs[count.index].name
  query = templatefile(
    "./templates/lb_internal_ssogen_http_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ssogen_internal
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}
