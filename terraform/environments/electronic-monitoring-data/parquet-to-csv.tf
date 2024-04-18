resource "aws_s3_bucket" "glue-jobs" {
    bucket_prefix = "glue-jobs-"
}

resource "aws_s3_object" "parquet-to-csv-job" {
    bucket = aws_s3_bucket.glue-jobs.id
    key = "parquet_to_csv.py"
    source = "glue-job/parquet_to_csv.py"
    etag = filemd5("glue-job/parquet_to_csv.py")
}


resource "aws_s3_bucket" "csv-output-bucket" {
    bucket_prefix = "data-to-ap-"
}

resource "aws_glue_job" "parquet-to-csv" {
    name = "parquet-to-csv"
    role_arn = aws_iam_role.parquet-to-csv.arn
    default_arguments = {
        "--destination_bucket" = aws_s3_bucket.csv-output-bucket.id
        "--source_bucket"      = "dms-em-rds-output"
    }

    command {
        script_location = "s3://${aws_s3_bucket.glue-jobs.id}/parquet_to_csv.py"
    }
}

resource "aws_iam_role" "parquet-to-csv" {
    name = "parquet-to-csv"
    assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
    inline_policy {
      name = "S3Policies"
      policy = data.aws_iam_policy_document.parquet-to-csv.json
    }
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
