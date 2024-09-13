data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}

resource "aws_iam_role" "dms_s3_writer_role" {
  name = local.dms_s3_writer_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "dms_s3_bucket_writer_policy" {
    count  = length(keys(local.dms_s3_cross_account_bucket_arns)) > 0 ? 1 : 0
    name   = "dms-s3-bucket-writer-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Effect    = "Allow"
        Action    = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:PutObjectTagging"         
        ]
        Resource = [for bucket in values(local.dms_s3_cross_account_bucket_arns) : "${bucket}/*"]
        },
        {
        Effect    = "Allow"
        Action    = [
          "s3:ListBucket"
        ]
        Resource = [for bucket in values(local.dms_s3_cross_account_bucket_arns) : bucket]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_writer_policy_attachment" {
  count      = length(keys(local.dms_s3_cross_account_bucket_arns)) > 0 ? 1 : 0
  role       = aws_iam_role.dms_s3_writer_role.name
  policy_arn = aws_iam_policy.dms_s3_bucket_writer_policy[0].arn
}


# The following role is used to allow the DMS service to read from the S3 Staging Bucket,
# And also to allow the name of the Repository Bucket to be found by the Client Account.
resource "aws_iam_role" "dms_s3_reader_role" {
  name = local.dms_s3_reader_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# The reader role only provides access to the local bucket, not those in other accounts
resource "aws_iam_policy" "dms_s3_bucket_reader_policy" {
    name   = "dms-s3-bucket-reader-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Effect    = "Allow"
        Action    = [
          "s3:GetObject"
        ]
        Resource = ["${module.s3_bucket_dms_destination.bucket.arn}/*"]
        },
        {
        Effect    = "Allow"
        Action    = [
          "s3:ListBucket"
        ]
        Resource = [module.s3_bucket_dms_destination.bucket.arn]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_reader_policy_attachment" {
  role       = aws_iam_role.dms_s3_reader_role.name
  policy_arn = aws_iam_policy.dms_s3_bucket_reader_policy.arn
}


# The following role is used to allow listing of all buckets so that the DMS S3 Staging Bucket may be found.
# This 1st version is used in client environments to allow the corresponding repository environment to list the local buckets.
resource "aws_iam_role" "dms_s3_bucket_list_by_repository_role" {
  count              = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  name               = local.dms_s3_lister_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
            AWS = "arn:aws:iam::${var.env_name_to_dms_config_map[var.dms_config.audit_target_endpoint.write_environment].account_id}:root"
          }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Policy to list all buckets in the current environment to allow searching for the DMS S3 Staging bucket
resource "aws_iam_policy" "dms_s3_bucket_list_by_repository_policy" {
  count       = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  name        =  "dms-s3-bucket-list-by-repository-policy"
  description = "Policy to allow listing of S3 buckets by DMS Audit repository."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListAllMyBuckets",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_list_by_repository_policy_attachment" {
  count      = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  role       = aws_iam_role.dms_s3_bucket_list_by_repository_role[0].name
  policy_arn = aws_iam_policy.dms_s3_bucket_list_by_repository_policy[0].arn
}


# This 2nd version is used in repository environments to allow the corresponding client environments to list the local buckets.
resource "aws_iam_role" "dms_s3_bucket_list_by_client_role" {
     count  = length(local.client_account_ids) > 0 ? 1 : 0
     name   = local.dms_s3_lister_role_name
     assume_role_policy = jsonencode({
     Version = "2012-10-17"
     Statement = [
         {
         Effect    = "Allow"
         Principal = {
            AWS = [for client_account_id in local.client_account_ids : "arn:aws:iam::${client_account_id}:root"]
         }
         Action    = "sts:AssumeRole"
         }
     ]
   })
}

# Policy to list all buckets in the current environment to allow searching for the DMS S3 Staging bucket
resource "aws_iam_policy" "dms_s3_bucket_list_by_client_policy" {
  count       = length(local.client_account_ids) > 0 ? 1 : 0
  name        = "dms-s3-bucket-list-by-client-policy"
  description = "Policy to allow listing of S3 buckets by DMS Audit client."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListAllMyBuckets",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_bucket_list_by_client_policy_attachment" {
  count      = length(local.client_account_ids) > 0 ? 1 : 0
  role       = aws_iam_role.dms_s3_bucket_list_by_client_role[0].name
  policy_arn = aws_iam_policy.dms_s3_bucket_list_by_client_policy[0].arn
}

# IAM Role for Lambda with AssumeRole policy
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

# Attach a policy that allows Lambda to assume roles in target accounts in order to list the buckets there
resource "aws_iam_policy" "assume_cross_account_policy" {
  count  = length(keys(local.bucket_list_target_map)) == 0 ? 0 : 1
  name   = "AssumeCrossAccountPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = [for delius_environment in keys(local.bucket_list_target_map) : "arn:aws:iam::${var.env_name_to_dms_config_map[delius_environment].account_id}:role/${delius_environment}-dms-s3-lister-role"]
      } 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_assume_role_attachment" {
  count      = length(keys(local.bucket_list_target_map)) == 0 ? 0 : 1
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.assume_cross_account_policy[0].arn
}


resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "APIGatewayCloudWatchLogsRole"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["apigateway.amazonaws.com","lambda.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_cloudwatch_policy" {
  name = "APIGatewayCloudWatchLogsPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_role_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = aws_iam_policy.api_gateway_cloudwatch_policy.arn
}


