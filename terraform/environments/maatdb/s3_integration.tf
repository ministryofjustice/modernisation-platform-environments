
locals {

  app_name = local.application_data.accounts[local.environment].application_name
  environment = local.application_data.accounts[local.environment].environment
  region = "eu-west-2"

  bucket_names = [
    "ftp-${app_name}-${environment}-outbouond",
    "ftp-${app_name}-${environment}-inbound",
  ]

}

# FTP Buckets

module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f" # v8.2.1

  bucket_prefix      = lower(each.key)
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy.json]
  # Enable bucket to be destroyed when not empty
  force_destroy = false
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = local.region
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 5
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(each.key) }
  )
}

# Bucket Policy

resource "aws_s3_bucket_policy" "ftp_user_access" {
  for_each = module.s3_bucket
  bucket = each.value.bucket
  policy = data.aws_iam_policy_document.bucket_policy[each.key].json
}

data "aws_iam_policy_document" "bucket_policy" {
  for_each = module.s3_bucket
  statement {
    sid    = "AllowFTPUserAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.ftp_user.arn]
    }
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      each.value.arn,
      "${each.value.arn}/*"
    ]
  }
}


# FTP IAM User
resource "aws_iam_user" "ftp_user" {
  name = "${local.app_name}-ftp-user"
}

resource "aws_iam_user_policy" "ftp_user_policy" {
  name   = "${local.application_name}-FTPUserPolicy"
  user   = aws_iam_user.ftp_user.name
  policy = data.aws_iam_policy_document.ftp_user_policy.json
}

data "aws_iam_policy_document" "ftp_user_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = flatten([
      for bucket in module.s3_bucket : [
        bucket.arn,
        "${bucket.arn}/*"
      ]
    ])
  }
}


# FTP Lambda

## IAM Resources

resource "aws_iam_role" "ftp_lambda_role" {
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
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.rftp_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ssm_access" {
  name = "AllowSSM"
  role = aws_iam_role.rftp_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_eni_access" {
  name = "VPCEniPolicy"
  role = aws_iam_role.rftp_lambda_role.id

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
  name = "S3BucketPolicy"
  role = aws_iam_role.rftp_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:*"],
        Resource = [
          "arn:aws:s3:::mikereid-ftp-testing",
          "arn:aws:s3:::mikereid-ftp-testing/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "SecretsManagerAccess"
  role = aws_iam_role.ftp_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.ftp_password.arn
      }
    ]
  })
}

## Lambda Layer

resource "aws_lambda_layer_version" "ftpclientlibs" {
  layer_name          = "ftpclientlibs"
  description         = "FtpClient Dependencies"
  compatible_runtimes = ["python3.9"]
  s3_bucket           = "mikereid-ftp-testing"
  s3_key              = "ftp-host/ftpclient-python-requirements.zip"
}

## Lambda Function

resource "aws_lambda_function" "rftp_lambda" {
  function_name = "rFTPLambda"
  description   = "FTP Files"
  runtime       = "python3.9"
  role          = aws_iam_role.rftp_lambda_role.arn
  handler       = "ftpclient.lambda_handler"
  timeout       = 300
  memory_size   = 256

  s3_bucket = "mikereid-ftp-testing"
  s3_key    = "ftp-host/ftpclient_1.2.zip"

  layers = [aws_lambda_layer_version.ftpclientlibs.arn]

  vpc_config {
    subnet_ids         = [""]
    security_group_ids = [""]
  }

  environment {
    variables = {
      HOST         = "10.231.0.229"
      PORT         = "22"
      PROTOCOL     = "sftp"
      FILETYPES    = "csv,xml,txt"
      TRANSFERTYPE = "binary"
      LOCALPATH    = "/outbound"
      REMOTEPATH   = "/home/sftpuser/incoming"
      REQUIRE_SSL  = "NO"
      INSECURE     = "YES"
      USER         = "sftpuser"
      PASSWORD     = "An3wP4ssw0rd"
      S3BUCKET     = "mikereid-ftp-testing"
      FILEREMOVE   = "NO"
    }
  }

  depends_on = [aws_iam_role_policy.s3_access]
}


## Secret for FTP Password

resource "aws_secretsmanager_secret" "ftp_password" {
  name = "${local.app_name}-${local.environment}-ftp-lambda-password"
}



