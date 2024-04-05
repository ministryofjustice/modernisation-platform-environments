resource "aws_s3_bucket" "glue-jobs" {
    bucket_prefix = "glue-jobs-"
}

resource "aws_s3_object" "parquet-to-csv-job" {
    bucket = aws_s3_bucket.glue-jobs.name
    key = "parquet_to_csv.py"
    source = "glue-job/parquet_to_csv.py"
    etag = filemd5("glue-job/parquet_to_csv.py")
}

resource "aws_glue_job" "parquet-to-csv" {
    name = "parquet-to-csv"
    role_arn = aws_iam_role.parquet_to_csv.arn

    command {
        script_location = "s3://${aws_s3_bucket.glue-jobs.name}/parquet_to_csv.py"
    }
}
