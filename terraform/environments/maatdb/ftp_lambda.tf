# FTP Lambda

locals {

  decoded_ftp_secret = try(
    jsondecode(
      length(data.aws_secretsmanager_secret_version.ftp_jobs_secret_version) > 0 ?
      data.aws_secretsmanager_secret_version.ftp_jobs_secret_version[0].secret_string :
      "{}"
    ),
    []
  )

  endpoint_details = {
    for pair in local.decoded_ftp_secret :
    "${pair.name}.${pair.type}" => pair.value
    if contains(keys(pair), "name") && contains(keys(pair), "type") && contains(keys(pair), "value")
  }

  ftp_job = {
    job_name       = "xerox-outbound"
    bucket_name    = try(module.s3_bucket.outbound.bucket.bucket, "")
    bucket_folder  = "export/home/ccmtdb/central_print/rep_orders/"
    ftp_protocol   = "SFTP"
    ftp_type       = "SFTP_UPLOAD"
    require_ssl    = "NO"
    insecure       = "YES"
    ftp_file_types = "zip"
    file_remove    = "YES"
    cron_rule      = local.application_data.accounts[local.environment].ftp_lambda_eventbridge_cron
  }

  zip_job = {
    job_name       = "xerox-outbound"
    bucket_name    = try(module.s3_bucket.outbound.bucket.bucket, "")
    bucket_folder  = "export/home/ccmtdb/central_print/rep_orders/"
    file_remove    = "YES"
    zip_file_types = "pdf,PDF,xml"
    cron_rule      = local.application_data.accounts[local.environment].zip_lambda_eventbridge_cron
  }

}

# IAM  Resources

resource "aws_iam_role" "ftp_lambda_role" {
  count = local.build_ftp ? 1 : 0
  name  = "rFTPLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(
    local.tags,
    {
      Name = "rFTPLambdaRole"
    }
  )
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  count      = local.build_ftp ? 1 : 0
  role       = aws_iam_role.ftp_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "general_lambda_access" {
  count = local.build_ftp ? 1 : 0
  name  = "GeneralLambdaAccess"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = "arn:aws:s3:::${local.ftp_layer_bucket}/laa-ftp/*"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${local.ftp_layer_bucket}"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:*:${local.environment_management.account_ids[terraform.workspace]}:*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "shared_kms_access" {
  count = local.build_ftp ? 1 : 0
  name  = "SharedKMSAccess"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Resource = local.laa_general_kms_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "secretsmanager_access" {
  count = local.build_ftp ? 1 : 0
  name  = "AllowSecretsManagerRead"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.ftp_jobs_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_eni_access" {
  #checkov:skip=CKV_AWS_290:"Accepted"
  #checkov:skip=CKV_AWS_355:"Accepted"
  count = local.build_ftp ? 1 : 0
  name  = "VPCEniPolicy"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  count = local.build_ftp ? 1 : 0
  name  = "S3BucketPolicy"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketPolicy",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = flatten([
          for bucket in module.s3_bucket : [
            bucket.bucket.arn,
            "${bucket.bucket.arn}/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy" "secrets_manager_access" {
  count = local.build_ftp ? 1 : 0
  name  = "SecretsManagerAccess"
  role  = aws_iam_role.ftp_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:Get*"
        ],
        Resource = aws_secretsmanager_secret.ftp_jobs_secret.arn
      }
    ]
  })
}


# Lambda layer
resource "aws_lambda_layer_version" "ftpclientlibs" {
  count               = local.build_ftp ? 1 : 0
  layer_name          = "ftpclientlibs"
  description         = "FtpClient Dependencies"
  compatible_runtimes = ["python3.12"]
  s3_bucket           = local.ftp_layer_bucket
  s3_key              = "${local.ftp_layer_folder_location}/${local.ftp_layer_source_zip}"
}


# Security Groups

resource "aws_security_group" "ftp_lambda" {
  count       = local.build_ftp ? 1 : 0
  name        = "ftp-lambda-${local.ftp_job.job_name}-sg"
  vpc_id      = data.aws_vpc.shared.id
  description = "ftp lambda security group"

  egress {
    description = "Allow SFTP outbound"
    from_port   = local.endpoint_details["${local.ftp_job.job_name}.remote-port"]
    to_port     = local.endpoint_details["${local.ftp_job.job_name}.remote-port"]
    protocol    = "tcp"
    cidr_blocks = ["${local.endpoint_details["${local.ftp_job.job_name}.remote-host"]}/32"]
  }

  egress {
    description = "S3 outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "zip_lambda" {
  count       = local.build_ftp ? 1 : 0
  name        = "zip-lambda-${local.ftp_job.job_name}-sg"
  vpc_id      = data.aws_vpc.shared.id
  description = "zip lambda security group"


  egress {
    description = "S3 outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Lambda that sends the zip bundle from the s3 folder to the remove endpoint

resource "aws_lambda_function" "ftp" {
  #checkov:skip=CKV_AWS_272:"To be ignored for now as not implemented in LZ lambdas"
  #checkov:skip=CKV_AWS_116:"To be ignored for now as not implemented in LZ lambdas"
  #checkov:skip=CKV_AWS_50:"To be ignored for now as not implemented in LZ lambdas"
  count         = local.build_ftp ? 1 : 0
  function_name = "${local.ftp_job.job_name}-ftp"
  role          = aws_iam_role.ftp_lambda_role[0].arn
  runtime       = local.python_runtime
  handler       = "ftpclient.lambda_handler"

  memory_size       = 512
  timeout           = 300
  s3_bucket         = local.ftp_layer_bucket
  s3_key            = "${local.ftp_layer_folder_location}/${local.ftp_lambda_source_file}"
  s3_object_version = local.ftp_lambda_source_file_version

  reserved_concurrent_executions = 1

  kms_key_arn = local.laa_general_kms_arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
    security_group_ids = [aws_security_group.ftp_lambda[0].id]
  }

  layers = [aws_lambda_layer_version.ftpclientlibs[0].arn]

  environment {
    variables = {
      HOST         = local.endpoint_details["${local.ftp_job.job_name}.remote-host"]
      PORT         = local.endpoint_details["${local.ftp_job.job_name}.remote-port"]
      PROTOCOL     = local.ftp_job.ftp_protocol
      FILETYPES    = local.ftp_job.ftp_file_types
      TRANSFERTYPE = local.ftp_job.ftp_type
      LOCALPATH    = local.ftp_job.bucket_folder
      REMOTEPATH   = local.endpoint_details["${local.ftp_job.job_name}.remote-folder"]
      REQUIRE_SSL  = local.ftp_job.require_ssl
      INSECURE     = local.ftp_job.insecure
      USER         = local.endpoint_details["${local.ftp_job.job_name}.username"]
      PASSWORD     = local.endpoint_details["${local.ftp_job.job_name}.password"]
      S3BUCKET     = local.ftp_job.bucket_name
      FILEREMOVE   = local.ftp_job.file_remove
    }
  }
}

# Lambda that generates the zip bundles

resource "aws_lambda_function" "zip" {
  #checkov:skip=CKV_AWS_272:"To be ignored for now as not implemented in LZ lambdas"
  #checkov:skip=CKV_AWS_116:"To be ignored for now as not implemented in LZ lambdas"
  #checkov:skip=CKV_AWS_50:"To be ignored for now as not implemented in LZ lambdas"
  count         = local.build_ftp ? 1 : 0
  function_name = "${local.zip_job.job_name}-zip"
  role          = aws_iam_role.ftp_lambda_role[0].arn
  runtime       = local.python_runtime
  handler       = "zip_s3_objects.lambda_handler"

  # Higher memory and timeout to support large numbers of files being zipped
  memory_size       = 4096
  timeout           = 900
  s3_bucket         = local.ftp_layer_bucket
  s3_key            = "${local.ftp_layer_folder_location}/${local.zip_lambda_source_file}"
  s3_object_version = local.zip_lambda_source_file_version

  reserved_concurrent_executions = 1

  kms_key_arn = local.laa_general_kms_arn

  # We max the ephemeral storage to support large numbers of files being zipped
  ephemeral_storage {
    size = 10240
  }

  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
    security_group_ids = [aws_security_group.zip_lambda[0].id]
  }

  layers = [aws_lambda_layer_version.ftpclientlibs[0].arn]

  environment {
    variables = {
      ARCHIVE_NAME     = "REPORDERS"
      BUCKET           = local.zip_job.bucket_name
      LOCALPATH        = local.zip_job.bucket_folder
      FILETYPES        = local.zip_job.zip_file_types
      REMOVEFILESAFTER = local.zip_job.file_remove
    }
  }
}

# EventBridge rules for lambda exec

# FTP

resource "aws_cloudwatch_event_rule" "ftp_cron_rule" {
  count               = local.build_ftp ? 1 : 0
  name                = "${local.ftp_job.job_name}-ftp-cron-rule"
  schedule_expression = local.ftp_job.cron_rule
}

resource "aws_cloudwatch_event_target" "ftp_lambda_target" {
  count     = local.build_ftp ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ftp_cron_rule[0].name
  target_id = "${local.ftp_job.job_name}-ftp-lambda"
  arn       = aws_lambda_function.ftp[0].arn
}

resource "aws_lambda_permission" "ftp_allow_eventbridge" {
  count         = local.build_ftp ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeFTP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ftp[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ftp_cron_rule[0].arn
}

# ZIP

resource "aws_cloudwatch_event_rule" "zip_cron_rule" {
  count               = local.build_ftp ? 1 : 0
  name                = "${local.ftp_job.job_name}-zip-cron-rule"
  schedule_expression = local.zip_job.cron_rule
}

resource "aws_cloudwatch_event_target" "zip_lambda_target" {
  count     = local.build_ftp ? 1 : 0
  rule      = aws_cloudwatch_event_rule.zip_cron_rule[0].name
  target_id = "${local.ftp_job.job_name}-zip-lambda"
  arn       = aws_lambda_function.zip[0].arn
}

resource "aws_lambda_permission" "zip_allow_eventbridge" {
  count         = local.build_ftp ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeZIP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zip[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.zip_cron_rule[0].arn
}
