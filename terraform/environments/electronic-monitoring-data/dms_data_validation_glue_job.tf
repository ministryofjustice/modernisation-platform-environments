resource "aws_s3_bucket" "dms_dv_parquet_s3_bucket" {
  #checkov:skip=CKV_AWS_144:Unsure of policy on this yet, should be covered by module - See ELM-1949
  #checkov:skip=CKV_AWS_145:Decide on a KMS key for encryption, should be covered by moudle - See ELM-1949
  #checkov:skip=CKV_AWS_18:AWS Access Logging should be enabled on S3 buckets, should be covered by module - See ELM-1949
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

resource "aws_s3_bucket" "dms_dv_glue_job_s3_bucket" {
  #checkov:skip=CKV_AWS_18:AWS Access Logging should be enabled on S3 buckets, should be covered by module - See ELM-1949
  bucket_prefix = "glue-jobs-py-scripts-"
}

resource "aws_s3_object" "dms_dv_glue_job_s3_object" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "dms_dv_rds_and_s3_csv.py"
  source = "glue-job/dms_dv_rds_and_s3_csv.py"
  etag   = filemd5("glue-job/dms_dv_rds_and_s3_csv.py")
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

resource "aws_cloudwatch_log_group" "dms_dv_cw_log_group" {
  name              = "dms-dv-glue-job"
  retention_in_days = 14
}

# -------------------------------------------------------------------

resource "aws_glue_job" "dms_dv_glue_job" {
  name         = "dms-dv-glue-job"
  description  = "DMS Data Validation Glue-Job (PySpark)."
  role_arn     = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version = "4.0"
  default_arguments = {
    "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                       = aws_db_instance.database_2022.password
    "--rds_sqlserver_db_list"            = ""
    "--csv_src_bucket_name"              = aws_s3_bucket.dms_target_ep_s3_bucket.id
    "--parquet_output_bucket_name"       = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
    "--glue_catalog_db_name"             = "${aws_glue_catalog_database.dms_dv_glue_catalog_db.name}"
    "--glue_catalog_tbl_name"            = "glue_df_output"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.dms_dv_cw_log_group.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }

  connections = ["${aws_glue_connection.glue_rds_sqlserver_db_connection.name}"]
  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/dms_dv_rds_and_s3_csv.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}
