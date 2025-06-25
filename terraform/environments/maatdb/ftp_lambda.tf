 # FTP Lambda

# Locals

# Accessing secrets into a list allowing for multiple ftp jobs.

locals {

  decoded_ftp_secret = try(
    jsondecode(data.aws_secretsmanager_secret_version.ftp_jobs_secret_version.secret_string),
    []
  )

  endpoint_details = {
    for pair in local.decoded_ftp_secret :
    "${pair.name}.${pair.type}" => pair.value
    if contains(keys(pair), "name") && contains(keys(pair), "type") && contains(keys(pair), "value")
  }


# This local is used to create the lambdas.

  ftp_job_definitions = [
    {
      job_name = "xerox_outbound"
      bucket   = module.s3_bucket.outbound.bucket.bucket
    }
  ]

  ftp_jobs = [
    for job in local.ftp_job_definitions : {
      job_name        = job.job_name
      bucket_name     = job.bucket
      bucket_folder   = "export/home/ccmtdb/central_print/rep_orders/"
      ftp_protocol    = "SFTP"
      ftp_type        = "SFTP_UPLOAD"
      require_ssl     = "NO"
      insecure        = "YES"
      file_types      = "zip"
      ftp_cron        = ""
      sns_topic_arn   = ""
      remote_host     = local.endpoint_details["${job.job_name}.remote-host"]
      remote_port     = local.endpoint_details["${job.job_name}.remote-port"]
      remote_folder   = local.endpoint_details["${job.job_name}.remote-folder"]
      username        = local.endpoint_details["${job.job_name}.username"]
      password        = local.endpoint_details["${job.job_name}.password"]
    }
  ]

# Global FTP Locals

  ftp_layer_bucket          = "modernisation-platform-laa-shared20250605080758955300000001"
  ftp_layer_folder_location = "laa_ftp/"
  ftp_source_location       = "laa_ftp/ftpclient_1.2.zip"
  ftp_source_version_id     = "LKYb32.Rqjizm17IiAsa.YZhOXfumTGj"


}

# ## IAM Resources

resource "aws_iam_role" "ftp_lambda_role" {
  count = local.build_ftp ? 1 : 0
  name = "rFTPLambdaRole"
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
  count = local.build_ftp ? 1 : 0
  role       = aws_iam_role.ftp_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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
  count = local.build_ftp ? 1 : 0
  name = "VPCEniPolicy"
  role = aws_iam_role.ftp_lambda_role[0].id

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
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
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
  name = "SecretsManagerAccess"
  role = aws_iam_role.ftp_lambda_role[0].id

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


# Lambda Layer. Pulls the layer compiled libs from the shared s3.

resource "aws_lambda_layer_version" "ftpclientlibs" {
  count = local.build_ftp ? 1 : 0
  layer_name          = "ftpclientlibs"
  description         = "FtpClient Dependencies"
  compatible_runtimes = ["python3.12"]
  s3_bucket           = "${local.application_data.accounts[local.environment].ftp_layer_bucket}"
  s3_key              = "${local.application_data.accounts[local.environment].ftp_layer_folder_location}/ftpclient-python-requirements.zip"
}

# FTP Lambda

resource "aws_lambda_function" "ftp" {
  for_each = local.build_ftp ? {
    for job in local.ftp_jobs : job.job_name => job
  } : {}

  function_name = each.value.job_name
  role          = aws_iam_role.ftp_lambda_role[0].arn
  runtime       = "python3.12"
  handler       = "ftpclient.lambda_handler"

  # Using the same bucket as the layer.
  s3_bucket = local.ftp_layer_bucket
  s3_key    = "${local.ftp_layer_bucket}/${local.ftp_source_location}}"
  s3_object_version = local.application_data.accounts[local.environment].ftp_source_version_id

  vpc_config {
    subnet_ids = [
      data.aws_subnet.private_subnets_a.id, 
      data.aws_subnet.private_subnets_b.id, 
      data.aws_subnet.private_subnets_c.id
    ]
    security_group_ids = [aws_security_group.lambda[each.key].id]
  }

  layers = [aws_lambda_layer_version.ftpclientlibs[0].arn]

  environment {
    variables = {
      BUCKET_NAME     = each.value.bucket_name
      BUCKET_FOLDER   = each.value.bucket_folder
      FTP_PROTOCOL    = each.value.ftp_protocol
      FTP_TYPE        = each.value.ftp_type
      REQUIRE_SSL     = each.value.require_ssl
      INSECURE        = each.value.insecure
      REMOTE_HOST     = each.value.remote_host
      REMOTE_PORT     = each.value.remote_port
      FILE_TYPES      = each.value.file_types
      FTP_CRON        = each.value.ftp_cron
      SNS_TOPIC_ARN   = each.value.sns_topic_arn
    }
  }

  tags = merge(
    local.tags,
    {
      Name = each.value.job_name
      Job  = each.key
    }
  )

}

resource "aws_security_group" "lambda" {
  for_each = local.build_ftp ? {
    for job in local.ftp_jobs : job.job_name => job
  } : {}

  name        = "lambda-${each.key}-sg"
  description = "Lambda SG for ${each.key}"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "Allow sftp outbound for ${each.key}"
    from_port   = each.value.remote_port
    to_port     = each.value.remote_port
    protocol    = "tcp"
    cidr_blocks = [each.value.remote_host]
  }

  tags = merge(
    local.tags,
    {
      Name = "lambda-${each.key}-sg"
      Job  = each.key
    }
  )

}



