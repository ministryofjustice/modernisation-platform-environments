resource "aws_s3_bucket" "glue_jobs" {
    bucket_prefix = "glue-jobs-"
}


resource "aws_glue_crawler" "rds_to_parquet" {
  database_name = aws_glue_catalog_database.rds_to_parquet.name
  name          = "rds_to_parquet"
  role          = aws_iam_role.rds_to_parquet_crawler.arn

  jdbc_target {
    connection_name = aws_glue_connection.rds_to_parquet.name
    path            = "%"
  }
}

resource "aws_glue_connection" "rds_to_parquet" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:sqlserver://${aws_db_instance.database_2022.endpoint}"
    PASSWORD            =  aws_secretsmanager_secret_version.db_password.secret_string
    USERNAME            = "admin"
  }

  name = "rds_to_parquet"

  physical_connection_requirements {
    security_group_id_list = [aws_security_group.db.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
  }
}

resource "aws_glue_catalog_database" "rds_to_parquet" {
  name = "rds_to_parquet"
}

resource "aws_iam_role" "rds_to_parquet_crawler" {
    name = "rds-to-parquet-glue"
    assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
    managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
}

data "aws_iam_policy_document" "rds_to_parquet_job" {
    statement {
        sid = "EC2RDSPermissions"
        effect = "Allow"
        actions = [
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusters",
            "rds:DescribeDBSnapshots",
            "rds:ListTagsForResource",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcs"
            ]
        principals {
          type = "Service"
          identifiers = ["rds.amazonaws.com"]
        }
    }
}


#------------------------------------------------------------------------------
# S3 bucket for glue job
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "rds_to_parquet" {
  bucket_prefix = "rds-to-parquet-"

  tags = local.tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "rds_to_parquet" {
  bucket = aws_s3_bucket.rds_to_parquet.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rds_to_parquet" {
  bucket                  = aws_s3_bucket.rds_to_parquet.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "rds_to_parquet" {
  bucket = aws_s3_bucket.rds_to_parquet.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "rds_to_parquet" {
  bucket = aws_s3_bucket.rds_to_parquet.id
  policy = data.aws_iam_policy_document.rds_to_parquet_bucket.json
}

data "aws_iam_policy_document" "rds_to_parquet_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.rds_to_parquet.arn,
      "${aws_s3_bucket.rds_to_parquet.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_logging" "rds_to_parquet" {
  bucket = aws_s3_bucket.rds_to_parquet.id

  target_bucket = aws_s3_bucket.rds_to_parquet.id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#-----------------------------------------------------------------------------
# Save glue job to s3 bucket
#------------------------------------------------------------------------------


# define variables
locals {
  layer_path        = "rds_to_parquet_job"
  layer_python_name    = "${local.layer_path}.py"
}


# upload zip file to s3
resource "aws_s3_object" "rds_to_parquet_glue_job" {
  bucket     = aws_s3_bucket.rds_to_parquet.id
  key        = "glue-job/${local.layer_python_name}"
  source     = local.layer_python_name
  depends_on = [local.layer_python_name]
}

resource "aws_glue_job" "rds_to_parquet_glue_job" {
  name     = "rds-to-parquet"
  role_arn = aws_iam_role.rds_to_parquet_job.arn

  command {
    script_location = "s3://${aws_s3_object.rds_to_parquet_glue_job.bucket}/${aws_s3_object.rds_to_parquet_glue_job.key}"
  }
}


data "aws_iam_policy_document" "rds_to_parquet_glue_job" {
    statement {
        sid = "EC2RDSPermissions"
        effect = "Allow"
        actions = [
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusters",
            "rds:DescribeDBSnapshots",
            "rds:ListTagsForResource",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcs"
            ]
        principals {
          type = "Service"
          identifiers = ["rds.amazonaws.com"]
        }
    }
  statement {
    sid = "AllowPutS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectAcl",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAttributes",
      "s3:ListBucket"
    ]
    resources = ["${aws_s3_bucket.rds_to_parquet.arn}/*"]
  }
}

resource "aws_iam_role" "rds_to_parquet_job" {
    name = "rds-to-parquet-glue-job"
    assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
    managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
}

resource "aws_iam_role_policy" "rds_to_parquet_job" {
  name   = "rds-to-parquet-job"
  role   = aws_iam_role.rds_to_parquet_job.id
  policy = data.aws_iam_policy_document.rds_to_parquet_glue_job.json
}