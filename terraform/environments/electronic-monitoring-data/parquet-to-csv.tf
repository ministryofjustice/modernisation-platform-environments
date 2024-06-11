resource "aws_s3_bucket" "glue-jobs" {
  bucket_prefix = "glue-jobs-"
}

resource "aws_s3_object" "parquet-to-csv-job" {
  bucket = aws_s3_bucket.glue-jobs.id
  key    = "parquet_to_csv.py"
  source = "glue-job/parquet_to_csv.py"
  etag   = filemd5("glue-job/parquet_to_csv.py")
}


resource "aws_s3_bucket" "csv-output-bucket" {
  bucket_prefix = "data-to-ap-"
}

resource "aws_s3_bucket_public_access_block" "csv-output-bucket" {
  bucket                  = aws_s3_bucket.csv-output-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "csv-output-bucket" {
  bucket = aws_s3_bucket.csv-output-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "csv-output-bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.csv-output-bucket.arn,
      "${aws_s3_bucket.csv-output-bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_policy" "csv-output-bucket" {
  bucket = aws_s3_bucket.csv-output-bucket.id
  policy = data.aws_iam_policy_document.csv-output-bucket.json
}

resource "aws_cloudwatch_log_group" "parquet-to-csv" {
  name              = "parquet-to-csv"
  retention_in_days = 14
}

resource "aws_glue_job" "parquet-to-csv" {
  name         = "parquet-to-csv"
  role_arn     = aws_iam_role.parquet-to-csv.arn
  glue_version = "4.0"
  default_arguments = {
    "--destination_bucket"               = aws_s3_bucket.csv-output-bucket.id
    "--source_bucket"                    = aws_s3_bucket.dms_target_ep_s3_bucket.id
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.parquet-to-csv.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }

  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.glue-jobs.id}/parquet_to_csv.py"
  }
}

resource "aws_iam_role" "parquet-to-csv" {
  name               = "parquet-to-csv"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  inline_policy {
    name   = "S3Policies"
    policy = data.aws_iam_policy_document.parquet-to-csv.json
  }
}

resource "aws_iam_role_policy_attachment" "glue_log_attachment" {
  role       = aws_iam_role.parquet-to-csv.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"

}


data "aws_iam_policy_document" "parquet-to-csv" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["${aws_s3_bucket.glue-jobs.arn}/*", aws_s3_bucket.glue-jobs.arn, "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*", aws_s3_bucket.dms_target_ep_s3_bucket.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.csv-output-bucket.arn, "${aws_s3_bucket.csv-output-bucket.arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetJob",
      "glue:GetJobs",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",

    ]
    resources = ["*"]
  }
}


