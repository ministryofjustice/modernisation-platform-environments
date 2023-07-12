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

# SQL query to creates the table in the athena db
resource "aws_athena_named_query" "main_table_ebsapp" {
  name      = lower(format("%s-%s-create-table", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ebsapp
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP
resource "aws_athena_named_query" "http_requests_ebsapp" {
  name      = lower(format("%s-%s-http-get-requests-ebsapp", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_http_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ebsapp
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}


resource "aws_athena_named_query" "main_table_wgate" {
  name      = lower(format("%s-%s-create-table", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_wgate
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

resource "aws_athena_named_query" "http_requests_wgate" {
  name      = lower(format("%s-%s-http-get-requests-wgate", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_http_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_wgate
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}