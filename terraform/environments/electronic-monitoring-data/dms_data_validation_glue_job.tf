resource "aws_s3_bucket" "dms_dv_parquet_s3_bucket" {
  bucket_prefix = "dms-data-validation-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "S3 Bucket for Athena Parquet Tables",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "dms_dv_parquet_s3_bucket" {
  bucket                  = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_dv_parquet_s3_bucket" {
  bucket = aws_s3_bucket.dms_dv_parquet_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dms_dv_parquet_s3_bucket" {
  bucket = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
  policy = data.aws_iam_policy_document.dms_dv_parquet_s3_bucket.json
}

# -------------------------------------------------------------------

resource "aws_glue_catalog_database" "dms_dv_glue_catalog_db" {
  name = "dms_data_validation"
  # create_table_default_permission {
  #   permissions = ["SELECT"]

  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

# -------------------------------------------------------------------

resource "aws_s3_bucket" "dms_dv_glue_job_s3_bucket" {
  bucket_prefix = "glue-jobs-py-scripts-"
}

resource "aws_s3_object" "dms_dv_glue_job_s3_object" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "dms_dv_rds_and_s3_csv.py"
  source = "glue-job/dms_dv_rds_and_s3_csv.py"
  etag   = filemd5("glue-job/dms_dv_rds_and_s3_csv.py")
}

# -------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "dms_dv_cw_log_group" {
  name              = "dms-dv-glue-job"
  retention_in_days = 14
}

resource "aws_iam_role" "dms_dv_glue_job_iam_role" {
  name               = "dms-dv-glue-job"
  assume_role_policy = data.aws_iam_policy_document.dms_dv_glue_assume_role.json

  inline_policy {
    name   = "S3Policies"
    policy = data.aws_iam_policy_document.dms_dv_iam_policy_document.json
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having Glue-Job execution policies",
    }
  )
}

resource "aws_iam_policy_attachment" "rds_readonly_policy_attachment" {
  name       = "rds-readonly-policy-attachment"
  roles      = [aws_iam_role.dms_dv_glue_job_iam_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"

}

resource "aws_iam_policy_attachment" "glue_service_role_policy_attachment" {
  name       = "glue-service-role-policy-attachment"
  roles      = [aws_iam_role.dms_dv_glue_job_iam_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"

}
resource "aws_glue_job" "dms_dv_glue_job" {
  name         = "dms-dv-glue-job"
  role_arn     = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version = "4.0"
  default_arguments = {
    "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                       = aws_db_instance.database_2022.password
    "--rds_db_list"                      = ""
    "--csv_src_bucket_name"              = aws_s3_bucket.dms_target_ep_s3_bucket.id
    "--parquet_target_bucket_name"       = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
    "--target_catalog_db_name"           = "dms_data_validation"
    "--target_catalog_tbl_name"          = "glue_df_output"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.dms_dv_cw_log_group.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }

  connections = ["glue-sqlserver-db-connection"]
  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/dms_dv_rds_and_s3_csv.py"
  }
}
