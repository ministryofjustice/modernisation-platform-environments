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
resource "aws_athena_named_query" "main_table_connector_internal" {
  name      = lower(format("%s-%s-create-table-connector-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_internal_table_connector.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.connector_app_name}-internal"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP 
resource "aws_athena_named_query" "http_requests_connector_internal" {
  name      = lower(format("%s-%s-http-get-requests-connector-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_internal_http_gets_connector.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.connector_app_name}-internal"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to creates the table in the athena db
resource "aws_athena_named_query" "main_table_opa_internal" {
  name      = lower(format("%s-%s-create-table-opa", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_internal_table_opa.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.opa_app_name}"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP 
resource "aws_athena_named_query" "http_requests_opa_internal" {
  name      = lower(format("%s-%s-http-get-requests-opa", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_internal_http_gets_opa.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.opa_app_name}"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to creates the table in the athena db
resource "aws_athena_named_query" "main_table_adapter_internal" {
  name      = lower(format("%s-%s-create-table-adaptor-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_internal_table_adaptor.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.adaptor_app_name}-internal"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP 
resource "aws_athena_named_query" "http_requests_adaptor_internal" {
  name      = lower(format("%s-%s-http-get-requests-adaptor-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_internal_http_gets_adaptor.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = "${local.adaptor_app_name}-internal"
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}