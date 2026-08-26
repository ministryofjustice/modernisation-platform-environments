resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket = module.s3-bucket-logging.bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = lower(format("%s-%s-lb-access-logs", "${local.application_data.accounts[local.environment].app_name}", local.environment))

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
resource "aws_athena_named_query" "main_table_admin" {
  name      = lower(format("%s-admin-%s-create-table", "${local.application_data.accounts[local.environment].app_name}", local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table_admin.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_soa_admin
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP, these queries needs to be executed manually after creation
resource "aws_athena_named_query" "tls_requests_admin" {
  name      = lower(format("%s-admin-%s-tls-version-get-requests", "${local.application_data.accounts[local.environment].app_name}", local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_tls_version_admin_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_soa_admin
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

resource "aws_athena_named_query" "main_table_managed" {
  name      = lower(format("%s-managed-%s-create-table", "${local.application_data.accounts[local.environment].app_name}", local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_table_managed.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_soa_managed
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

resource "aws_athena_named_query" "tls_requests_managed" {
  name      = lower(format("%s-managed-%s-tls-version-get-requests", "${local.application_data.accounts[local.environment].app_name}", local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_tls_version_managed_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_soa_managed
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}
