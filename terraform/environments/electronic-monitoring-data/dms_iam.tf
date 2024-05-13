# Database Migration Service requires the below IAM Roles to be created before replication instances can be created. 

# Define IAM role for DMS S3 Endpoint
resource "aws_iam_role" "dms_endpoint_role" {
  name               = "dms-endpoint-access-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS-Endpoint access policies",
    }
  )

}

# Define S3 IAM policy for DMS S3 Endpoint
resource "aws_iam_policy" "dms_ep_s3_role_policy" {
  name = "dms-s3-target-ep-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DMSAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}"
        },
        {
            "Sid": "DMSObjectActions",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*"
        }
    ]
}
EOF
}

# Attach predefined IAM Policy to the Role for DMS S3 Endpoint
resource "aws_iam_role_policy_attachment" "dms_ep_s3_role_policy_attachment" {
  role       = aws_iam_role.dms_endpoint_role.name
  policy_arn = aws_iam_policy.dms_ep_s3_role_policy.arn
}

# -------------------------------------------------------------

resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name                = "dms-cloudwatch-logs-role"
  assume_role_policy  = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS-Cloudwatch-Logs access policies",
    }
  )
}

# -------------------------------------------------------------

# Error: creating DMS Replication Subnet Group (rds-replication-subnet-group-tf): AccessDeniedFault: The IAM Role arn:aws:iam::############:role/dms-vpc-role is not configured properly.
resource "aws_iam_role" "dms_vpc_role" {
  name                = "dms-vpc-role"
  assume_role_policy  = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS access policies",
    }
  )
}

# -------------------------------------------------------------

resource "aws_iam_role" "dms_dv_glue_job_iam_role" {
  name               = "dms-dv-glue-job-tf"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  ]
  inline_policy {
    name   = "S3Policies"
    policy = data.aws_iam_policy_document.dms_dv_s3_iam_policy_document.json
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having Glue-Job execution policies",
    }
  )
  lifecycle {
    create_before_destroy = false
  }
}

# -------------------------------------------------------------
# Define IAM role for DMS S3 Endpoint
resource "aws_iam_role" "dms_endpoint_role_parquet" {
  name               = "dms-parquet-endpoint-access-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS-Endpoint access policies",
    }
  )

}

# Define S3 IAM policy for DMS S3 Endpoint
resource "aws_iam_role_policy_attachment" "dms_ep_s3_role_parquet_bucket_policy" {
  role = aws_iam_role.dms_endpoint_role_parquet.name
  policy_arn = aws_iam_policy.dms_ep_s3_role_parquet_bucket.arn
}

resource "aws_iam_role_policy_attachment" "dms_ep_s3_role_parquet_files_policy" {
  role = aws_iam_role.dms_endpoint_role_parquet.name
  policy_arn = aws_iam_policy.dms_ep_s3_role_parquet_files.arn
}

resource "aws_iam_policy" "dms_ep_s3_role_parquet_bucket" {
  name = "get-dms-parquet-buckets"
  policy = data.aws_iam_policy_document.dms_ep_s3_role_parquet_bucket.json
}

resource "aws_iam_policy" "dms_ep_s3_role_parquet_files" {
  name = "get-dms-parquet-buckets"
  policy = data.aws_iam_policy_document.dms_ep_s3_role_parquet_files.json
}

data "aws_iam_policy_document" "dms_ep_s3_role_parquet_bucket" {
  statement {
    effect = "Allow"
    resources = [aws_s3_bucket.dms_target_ep_s3_bucket_parquet.arn]
    actions = [                
      "s3:GetBucketLocation",
      "s3:ListBucket"
      ]
    sid = "DMSParquetEndpointAccess"
  }
}

data "aws_iam_policy_document" "dms_ep_s3_role_parquet_files" {
  statement {
    effect = "Allow"
    resources = ["${aws_s3_bucket.dms_target_ep_s3_bucket_parquet.arn}/*"]
    actions = [                
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
      ]
    sid = "DMSParquetGetAccess"
  }
}