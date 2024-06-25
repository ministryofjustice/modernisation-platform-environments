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

resource "aws_s3_bucket" "dms_dv_glue_job_s3_bucket" {
  bucket_prefix = "glue-jobs-py-scripts-"
}

resource "aws_s3_object" "dms_dv_glue_job_s3_object_v2" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "dms_dv_rds_and_s3_parquet_write_v2.py"
  source = "glue-job/dms_dv_rds_and_s3_parquet_write_v2.py"
  etag   = filemd5("glue-job/dms_dv_rds_and_s3_parquet_write_v2.py")
}

resource "aws_s3_object" "dms_dv_glue_job_s3_object_v3" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "dms_dv_rds_and_s3_parquet_write_v3.py"
  source = "glue-job/dms_dv_rds_and_s3_parquet_write_v3.py"
  etag   = filemd5("glue-job/dms_dv_rds_and_s3_parquet_write_v3.py")
}
resource "aws_s3_object" "catalog_dv_table_glue_job_s3_object" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "create_or_replace_dv_table.py"
  source = "glue-job/create_or_replace_dv_table.py"
  etag   = filemd5("glue-job/create_or_replace_dv_table.py")
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

resource "aws_glue_job" "dms_dv_glue_job_v2" {
  name              = "dms-dv-glue-job-v2"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 8
  default_arguments = {
    "--script_bucket_name"                = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                  = ""
    "--rds_sqlserver_db_schema"           = ""
    "--rds_exclude_db_tbls"               = ""
    "--rds_select_db_tbls"                = ""
    "--rds_df_trim_str_columns"           = "false"
    "--rds_df_trim_micro_sec_ts_col_list" = ""
    "--repartition_factor"                = 8
    "--max_table_size_mb"                 = 4000
    "--parquet_src_bucket_name"           = aws_s3_bucket.dms_target_ep_s3_bucket.id
    "--parquet_output_bucket_name"        = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
    "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"             = "glue_df_output"
    "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_cw_log_group.name}"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true"
    "--enable-spark-ui"                   = "false"
    "--spark-event-logs-path"             = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/spark_logs/"
    "--enable-metrics"                    = "true"
    "--enable-auto-scaling"               = "true"
    "--conf"                              = "spark.memory.offHeap.enabled=true --conf spark.memory.offHeap.size=1g --conf spark.sql.adaptive.enabled=true --conf spark.sql.adaptive.coalescePartitions.enabled=true --conf spark.sql.adaptive.skewJoin.enabled=true --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED"
  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/dms_dv_rds_and_s3_parquet_write_v2.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}

resource "aws_glue_job" "dms_dv_glue_job_v3" {
  name              = "dms-dv-glue-job-v3"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                  = ""
    "--rds_sqlserver_db_schema"           = ""
    "--rds_sqlserver_db_table"            = ""
    "--rds_db_tbl_pkeys_col_list"         = ""
    "--rds_df_trim_str_col_list"          = ""
    "--rds_df_trim_micro_sec_ts_col_list" = ""
    "--repartition_factor"                = 8
    "--parquet_src_bucket_name"           = aws_s3_bucket.dms_target_ep_s3_bucket.id
    "--parquet_output_bucket_name"        = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
    "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"             = "glue_df_output"
    "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_cw_log_group.name}"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true"
    "--enable-spark-ui"                   = "false"
    "--spark-event-logs-path"             = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/spark_logs/"
    "--enable-metrics"                    = "true"
    "--enable-auto-scaling"               = "true"
    "--conf"                              = "spark.memory.offHeap.enabled=true --conf spark.memory.offHeap.size=1g --conf spark.sql.adaptive.enabled=true --conf spark.sql.adaptive.coalescePartitions.enabled=true --conf spark.sql.adaptive.skewJoin.enabled=true --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED"
  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/dms_dv_rds_and_s3_parquet_write_v3.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}

resource "aws_glue_job" "catalog_dv_table_glue_job" {
  name              = "catalog-dv-table-glue-job"
  description       = "Python script uses Boto3-Athena-Client to run sql-statements"
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  default_arguments = {
    "--parquet_output_bucket_name"       = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
    "--glue_catalog_db_name"             = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"            = "glue_df_output"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.dms_dv_cw_log_group.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }
  command {
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/create_or_replace_dv_table.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Py script as glue-job that creates dv table / refreshes its partitions",
    }
  )

}
