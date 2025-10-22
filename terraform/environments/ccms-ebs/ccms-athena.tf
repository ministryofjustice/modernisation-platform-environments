# IAM role for Athena
# resource "aws_iam_role" "athena_role" {
#   name = "athena-query-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "athena.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "athena_policy" {
#   name = "athena-query-execution-policy"
#   role = aws_iam_role.athena_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetBucketLocation",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:ListBucketMultipartUploads",
#           "s3:ListMultipartUploadParts",
#           "s3:AbortMultipartUpload",
#           "s3:CreateBucket",
#           "s3:PutObject"
#         ]
#         Resource = [
#           module.s3-bucket-logging.bucket.arn,
#           "${module.s3-bucket-logging.bucket.arn}/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "athena:StartQueryExecution",
#           "athena:GetQueryExecution",
#           "athena:GetQueryResults"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }


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

# SQL query to creates the table in the athena db
resource "aws_athena_named_query" "main_table_ebsapp_internal" {
  name      = lower(format("%s-%s-create-table-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/create_internal_table.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ebsapp_internal
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# SQL query to count the number of HTTP GET requests to the loadbalancer grouped by IP
resource "aws_athena_named_query" "http_requests_ebsapp_internal" {
  name      = lower(format("%s-%s-http-get-requests-ebsapp-internal", local.application_name, local.environment))
  workgroup = aws_athena_workgroup.lb-access-logs.id
  database  = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "./templates/lb_internal_http_gets.sql",
    {
      bucket     = module.s3-bucket-logging.bucket.id
      key        = local.lb_log_prefix_ebsapp_internal
      account_id = data.aws_caller_identity.current.id
      region     = data.aws_region.current.id
    }
  )
}

# resource "aws_athena_named_query" "main_table_wgate" {
#   name      = lower(format("%s-%s-create-table", local.application_name, local.environment))
#   workgroup = aws_athena_workgroup.lb-access-logs.id
#   database  = aws_athena_database.lb-access-logs.name
#   query = templatefile(
#     "./templates/create_table.sql",
#     {
#       bucket     = module.s3-bucket-logging.bucket.id
#       key        = local.lb_log_prefix_wgate
#       account_id = data.aws_caller_identity.current.id
#       region     = data.aws_region.current.id
#     }
#   )
# }

# resource "aws_athena_named_query" "http_requests_wgate" {
#   name      = lower(format("%s-%s-http-get-requests-wgate", local.application_name, local.environment))
#   workgroup = aws_athena_workgroup.lb-access-logs.id
#   database  = aws_athena_database.lb-access-logs.name
#   query = templatefile(
#     "./templates/lb_http_gets.sql",
#     {
#       bucket     = module.s3-bucket-logging.bucket.id
#       key        = local.lb_log_prefix_wgate
#       account_id = data.aws_caller_identity.current.id
#       region     = data.aws_region.current.id
#     }
#   )
# }