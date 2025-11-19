resource "aws_glue_security_configuration" "em_glue_security_configuration" {
  count = local.is-production || local.is-development ? 1 : 0
  #checkov:skip=CKV_AWS_99
  name = "em-glue-security-configuration"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      s3_encryption_mode = "DISABLED"
    }
  }
}

resource "aws_s3_object" "aws_s3_object_pyzipfile_to_s3folder" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "${var.s3_pylib_dir_path}/glue_data_validation_lib.zip"
  source      = data.archive_file.archive_file_zip_py_files.output_path
  acl         = "private"
  source_hash = filemd5(data.archive_file.archive_file_zip_py_files.output_path)
}


resource "aws_cloudwatch_log_group" "dms_dv_rds_to_s3_parquet_v1" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "dms-dv-rds-to-s3-parquet-v1"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "dms_dv_rds_to_s3_parquet_v1" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "dms_dv_rds_to_s3_parquet_v1.py"
  source      = "glue-job/dms_dv_rds_to_s3_parquet_v1.py"
  source_hash = filemd5("glue-job/dms_dv_rds_to_s3_parquet_v1.py")
}

resource "aws_glue_job" "dms_dv_rds_to_s3_parquet_v1" {
  count = local.gluejob_count

  name              = "dms-dv-rds-to-s3-parquet_v1"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                       = aws_db_instance.database_2022[0].password
    "--rds_sqlserver_db"                 = ""
    "--rds_sqlserver_db_schema"          = "dbo"
    "--rds_exclude_db_tbls"              = ""
    "--rds_select_db_tbls"               = ""
    "--rds_db_tbl_pkeys_col_list"        = ""
    "--rds_df_trim_str_columns"          = "false"
    "--skip_columns_comparison"          = ""
    "--num_of_repartitions"              = 0
    "--read_partition_size_mb"           = 128
    "--max_table_size_mb"                = 4000
    "--parquet_tbl_folder_if_different"  = ""
    "--extra-py-files"                   = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--parquet_src_bucket_name"          = module.s3-dms-target-store-bucket.bucket.id
    "--parquet_output_bucket_name"       = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"             = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"            = "glue_df_output"
    "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_rds_to_s3_parquet_v1[0].name}"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-auto-scaling"              = "true"
    "--conf"                             = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=128m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_to_s3_parquet_v1.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name
  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}
# ------------------------------------------------------------------------------------------------------
# Note: Make sure 'max_table_size_mb' and 'spark.sql.files.maxPartitionBytes' values are the same.

# "--enable-spark-ui"                   = "false"
# "--spark-ui-event-logs-path"          = "false"
# "--spark-event-logs-path"             = "s3://${module.s3-glue-job-script-bucket.bucket.id}/spark_logs/"
# ------------------------------------------------------------------------------------------------------


resource "aws_cloudwatch_log_group" "dms_dv_rds_to_s3_parquet_v2" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "dms-dv-rds-to-s3-parquet-v2"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "dms_dv_rds_to_s3_parquet_v2" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "dms_dv_rds_to_s3_parquet_v2.py"
  source      = "glue-job/dms_dv_rds_to_s3_parquet_v2.py"
  source_hash = filemd5("glue-job/dms_dv_rds_to_s3_parquet_v2.py")
}

resource "aws_glue_job" "dms_dv_rds_to_s3_parquet_v2" {
  count = local.gluejob_count

  name              = "dms-dv-rds-to-s3-parquet-v2"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022[0].password
    "--parquet_df_repartition_num"        = 24
    "--parallel_jdbc_conn_num"            = 4
    "--rds_df_repartition_num"            = 0
    "--rds_upperbound_factor"             = 1
    "--rds_sqlserver_db"                  = ""
    "--rds_sqlserver_db_schema"           = "dbo"
    "--rds_sqlserver_db_table"            = ""
    "--rds_db_tbl_pkeys_col_list"         = ""
    "--rds_df_trim_str_columns"           = "false"
    "--rds_df_trim_micro_sec_ts_col_list" = ""
    "--extra-py-files"                    = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--parquet_src_bucket_name"           = module.s3-dms-target-store-bucket.bucket.id
    "--parquet_output_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"             = "glue_df_output"
    "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_rds_to_s3_parquet_v2[0].name}"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true"
    "--enable-metrics"                    = "true"
    "--enable-auto-scaling"               = "true"
    "--conf"                              = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.shuffle.partitions=2001 
--conf spark.sql.files.maxPartitionBytes=1g 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_to_s3_parquet_v2.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name
  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}


# resource "aws_cloudwatch_log_group" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   name              = "etl-rds-to-s3-parquet-partitionby-yyyy-mm"
#   retention_in_days = 365
#   kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
# }

# resource "aws_s3_object" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   source = "glue-job/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   source_hash = filemd5("glue-job/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py")
# }

# resource "aws_glue_job" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   count = local.gluejob_count

#   name              = "etl-rds-to-s3-parquet-partitionby-yyyy-mm"
#   description       = "Table migration Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 4
#   default_arguments = {
#     "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022[0].endpoint)[0]
#     "--rds_db_pwd"                       = aws_db_instance.database_2022[0].password
#     "--rds_sqlserver_db"                 = ""
#     "--rds_sqlserver_db_schema"          = "dbo"
#     "--rds_sqlserver_db_table"           = ""
#     "--rds_query_where_clause"           = ""
#     "--rds_db_tbl_pkeys_col_list"        = ""
#     "--date_partition_column_name"       = ""
#     "--other_partitionby_columns"        = ""
#     "--jdbc_read_partition_num"          = 1
#     "--rds_df_repartition_num"           = 0
#     "--coalesce_int"                     = 0
#     "--rename_migrated_prq_tbl_folder"   = ""
#     "--year_partition_bool"              = "true"
#     "--month_partition_bool"             = "true"
#     "--extra-py-files"                   = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
#     "--rds_to_parquet_output_s3_bucket"  = module.s3-dms-target-store-bucket.bucket.id
#     "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_rds_to_s3_parquet_partitionby_yyyy_mm.name}"
#     "--enable-continuous-cloudwatch-log" = "true"
#     "--enable-continuous-log-filter"     = "true"
#     "--enable-metrics"                   = "true"
#     "--enable-auto-scaling"              = "true"
#     "--conf"                             = <<EOF
# spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
# --conf spark.sql.sources.partitionOverwriteMode=dynamic 
# --conf spark.sql.parquet.aggregatePushdown=true 
# EOF

#   }

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   }
#   security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name


#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }


# resource "aws_cloudwatch_log_group" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   name              = "etl-dv-rds-to-s3-parquet-partitionby-yyyy-mm"
#   retention_in_days = 365
#   kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
# }

# resource "aws_s3_object" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   source = "glue-job/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   source_hash = filemd5("glue-job/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py")
# }

# resource "aws_glue_job" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
#   count = local.gluejob_count

#   name              = "etl-dv-rds-to-s3-parquet-partitionby-yyyy-mm"
#   description       = "Table migration & validation Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 4
#   default_arguments = {
#     "--script_bucket_name"                   = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                       = split(":", aws_db_instance.database_2022[0].endpoint)[0]
#     "--rds_db_pwd"                           = aws_db_instance.database_2022[0].password
#     "--rds_sqlserver_db"                     = ""
#     "--rds_sqlserver_db_schema"              = "dbo"
#     "--rds_sqlserver_db_table"               = ""
#     "--rds_query_where_clause"               = ""
#     "--rds_db_tbl_pkeys_col_list"            = ""
#     "--rds_table_total_size_mb"              = 0
#     "--rds_df_repartition_num"               = 0
#     "--date_partition_column_name"           = ""
#     "--validation_sample_fraction_float"     = 0
#     "--validation_sample_df_repartition_num" = 0
#     "--jdbc_read_256mb_partitions"           = "false"
#     "--jdbc_read_512mb_partitions"           = "false"
#     "--jdbc_read_1gb_partitions"             = "false"
#     "--jdbc_read_2gb_partitions"             = "false"
#     "--jdbc_read_partition_num"              = 1
#     "--rename_migrated_prq_tbl_folder"       = ""
#     "--add_year_partition_bool"              = "false"
#     "--add_month_partition_bool"             = "false"
#     "--validation_only_run"                  = "true"
#     "--rds_df_year_int_equals_to"            = 0
#     "--rds_df_month_int_equals_to"           = 0
#     "--extra-py-files"                       = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
#     "--rds_to_parquet_output_s3_bucket"      = module.s3-dms-target-store-bucket.bucket.id
#     "--dv_parquet_output_s3_bucket"          = module.s3-dms-data-validation-bucket.bucket.id
#     "--glue_catalog_db_name"                 = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
#     "--glue_catalog_tbl_name"                = "glue_df_output"
#     "--continuous-log-logGroup"              = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.name}"
#     "--enable-continuous-cloudwatch-log"     = "true"
#     "--enable-continuous-log-filter"         = "true"
#     "--enable-metrics"                       = "true"
#     "--enable-auto-scaling"                  = "true"
#     "--conf"                                 = <<EOF
# spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
# --conf spark.sql.sources.partitionOverwriteMode=dynamic 
# --conf spark.sql.parquet.aggregatePushdown=true 
# --conf spark.sql.files.maxPartitionBytes=256m 
# EOF

#   }

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
#   }
#   security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }


resource "aws_cloudwatch_log_group" "parquet_resize_or_partitionby_yyyy_mm_dd" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "parquet-resize-or-partitionby-yyyy-mm-dd"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "parquet_resize_or_partitionby_yyyy_mm_dd" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "parquet_resize_or_partitionby_yyyy_mm_dd.py"
  source      = "glue-job/parquet_resize_or_partitionby_yyyy_mm_dd.py"
  source_hash = filemd5("glue-job/parquet_resize_or_partitionby_yyyy_mm_dd.py")
}

resource "aws_glue_job" "parquet_resize_or_partitionby_yyyy_mm_dd" {
  count = local.gluejob_count

  name              = "parquet-resize-or-partitionby-yyyy-mm-dd"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
    "--s3_prq_read_db_folder"            = ""
    "--s3_prq_read_db_schema_folder"     = "dbo"
    "--s3_prq_read_table_folder"         = ""
    "--s3_prq_write_table_folder"        = ""
    "--primarykey_column"                = ""
    "--date_partition_column"            = ""
    "--s3_prq_df_read_where_clause"      = ""
    "--year_int_equals_to"               = 0
    "--month_int_equals_to"              = 0
    "--prq_df_repartition_int"           = 0
    "--coalesce_int"                     = 0
    "--add_year_partition_bool"          = "true"
    "--add_month_partition_bool"         = "true"
    "--extra-py-files"                   = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--s3_prq_read_bucket_name"          = module.s3-dms-target-store-bucket.bucket.id
    "--s3_prq_write_bucket_name"         = module.s3-dms-target-store-bucket.bucket.id
    "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.parquet_resize_or_partitionby_yyyy_mm_dd[0].name}"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-auto-scaling"              = "true"
    "--conf"                             = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=512m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/parquet_resize_or_partitionby_yyyy_mm_dd.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}


resource "aws_cloudwatch_log_group" "etl_table_rows_hashvalue_to_parquet" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "etl-table-rows-hashvalue-to-parquet"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "etl_table_rows_hashvalue_to_parquet" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "etl_table_rows_hashvalue_to_parquet.py"
  source      = "glue-job/etl_table_rows_hashvalue_to_parquet.py"
  source_hash = filemd5("glue-job/etl_table_rows_hashvalue_to_parquet.py")
}

resource "aws_glue_job" "etl_table_rows_hashvalue_to_parquet" {
  count = local.gluejob_count

  name              = "etl-table-rows-hashvalue-to-parquet"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                  = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                      = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                          = aws_db_instance.database_2022[0].password
    "--rds_sqlserver_db"                    = ""
    "--rds_sqlserver_db_schema"             = "dbo"
    "--rds_sqlserver_db_table"              = ""
    "--rds_db_tbl_pkey_column"              = ""
    "--rds_db_table_hashed_rows_parent_dir" = "rds_tables_rows_hashed"
    "--parallel_jdbc_conn_num"              = 1
    "--parquet_df_write_repartition_num"    = 0
    "--extra-py-files"                      = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--hashed_output_s3_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"                = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--continuous-log-logGroup"             = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_table_rows_hashvalue_to_parquet[0].name}"
    "--enable-continuous-cloudwatch-log"    = "true"
    "--enable-continuous-log-filter"        = "true"
    "--enable-metrics"                      = "true"
    "--enable-auto-scaling"                 = "true"
    "--conf"                                = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=256m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_table_rows_hashvalue_to_parquet.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}



resource "aws_cloudwatch_log_group" "dms_dv_on_rows_hashvalue" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "dms-dv-on-rows-hashvalue"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "dms_dv_on_rows_hashvalue" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "dms_dv_on_rows_hashvalue.py"
  source      = "glue-job/dms_dv_on_rows_hashvalue.py"
  source_hash = filemd5("glue-job/dms_dv_on_rows_hashvalue.py")
}

resource "aws_glue_job" "dms_dv_on_rows_hashvalue" {
  count = local.gluejob_count

  name              = "dms-dv-on-rows-hashvalue"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                       = aws_db_instance.database_2022[0].password
    "--rds_database_folder"              = ""
    "--rds_db_schema_folder"             = "dbo"
    "--table_to_be_validated"            = ""
    "--table_pkey_column"                = ""
    "--rds_hashed_rows_prq_parent_dir"   = "rds_tables_rows_hashed"
    "--dms_prq_output_bucket"            = module.s3-dms-target-store-bucket.bucket.id
    "--rds_hashed_rows_prq_bucket"       = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_dv_bucket"           = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"             = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"            = "glue_df_output"
    "--extra-py-files"                   = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_on_rows_hashvalue[0].name}"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-auto-scaling"              = "true"
    "--conf"                             = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=256m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_on_rows_hashvalue.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}



resource "aws_cloudwatch_log_group" "etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "etl-rds-tbl-rows-hashvalue-to-s3-prq-yyyy-mm"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm.py"
  source      = "glue-job/etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm.py"
  source_hash = filemd5("glue-job/etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm.py")
}

resource "aws_glue_job" "etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm" {
  count = local.gluejob_count

  name              = "etl-rds-tbl-rows-hashvalue-to-s3-prq-yyyy-mm"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 2

  execution_property {
    max_concurrent_runs = 12
  }

  default_arguments = {
    "--script_bucket_name"                  = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                      = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                          = aws_db_instance.database_2022[0].password
    "--rds_sqlserver_db"                    = ""
    "--rds_sqlserver_db_schema"             = "dbo"
    "--rds_sqlserver_db_table"              = ""
    "--rds_db_tbl_pkey_column"              = ""
    "--date_partition_column_name"          = ""
    "--pkey_lower_bound_int"                = ""
    "--pkey_upper_bound_int"                = ""
    "--parallel_jdbc_conn_num"              = 2
    "--rds_yyyy_mm_df_repartition_num"      = 0
    "--year_partition_bool"                 = "true"
    "--month_partition_bool"                = "true"
    "--rds_db_table_hashed_rows_parent_dir" = "rds_tables_rows_hashed"
    "--incremental_run_bool"                = "false"
    "--rds_query_where_clause"              = ""
    "--df_where_clause"                     = ""
    "--skip_columns_for_hashing"            = ""
    "--coalesce_int"                        = 0
    "--extra-py-files"                      = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--hashed_output_s3_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"                = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--continuous-log-logGroup"             = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm[0].name}"
    "--enable-continuous-cloudwatch-log"    = "true"
    "--enable-continuous-log-filter"        = "true"
    "--enable-metrics"                      = "true"
    "--enable-auto-scaling"                 = "true"
    "--conf"                                = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=256m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_rds_tbl_rows_hashvalue_to_s3_prq_yyyy_mm.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}

resource "aws_cloudwatch_log_group" "etl_rds_sqlserver_query_to_s3_parquet" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "etl-rds-sqlserver-query-to-s3-parquet"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "etl_rds_sqlserver_query_to_s3_parquet" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "etl_rds_sqlserver_query_to_s3_parquet.py"
  source      = "glue-job/etl_rds_sqlserver_query_to_s3_parquet.py"
  source_hash = filemd5("glue-job/etl_rds_sqlserver_query_to_s3_parquet.py")
}

resource "aws_glue_job" "etl_rds_sqlserver_query_to_s3_parquet" {
  count = local.gluejob_count

  name              = "etl-rds-sqlserver-query-to-s3-parquet"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                   = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                       = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                           = aws_db_instance.database_2022[0].password
    "--jdbc_read_partitions_num"             = 0
    "--rds_sqlserver_db"                     = ""
    "--rds_sqlserver_db_schema"              = "dbo"
    "--rds_sqlserver_db_table"               = ""
    "--rds_db_tbl_pkey_column"               = ""
    "--rds_df_repartition_num"               = 0
    "--rename_migrated_prq_tbl_folder"       = ""
    "--validation_only_run"                  = "false"
    "--validation_sample_fraction_float"     = 0
    "--validation_sample_df_repartition_num" = 0
    "--extra-py-files"                       = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--rds_to_parquet_output_s3_bucket"      = module.s3-dms-target-store-bucket.bucket.id
    "--glue_catalog_dv_bucket"               = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"                 = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"                = "glue_df_output"
    "--continuous-log-logGroup"              = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_rds_sqlserver_query_to_s3_parquet[0].name}"
    "--enable-continuous-cloudwatch-log"     = "true"
    "--enable-continuous-log-filter"         = "true"
    "--enable-metrics"                       = "true"
    "--enable-auto-scaling"                  = "true"
    "--conf"                                 = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=128m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_rds_sqlserver_query_to_s3_parquet.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}


# -------------------------------------------------------------------

resource "aws_glue_catalog_database" "dms_dv_glue_catalog_db" {
  count = local.is-production || local.is-development ? 1 : 0
  name  = "dms_data_validation"
  # create_table_default_permission {
  #   permissions = ["SELECT"]

  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

# -------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "create_or_refresh_dv_table" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "create-or-refresh-dv-table"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}


resource "aws_s3_object" "create_or_refresh_dv_table" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "create_or_refresh_dv_table.py"
  source      = "glue-job/create_or_refresh_dv_table.py"
  source_hash = filemd5("glue-job/create_or_refresh_dv_table.py")
}

resource "aws_glue_job" "create_or_refresh_dv_table" {
  count = local.gluejob_count

  name              = "create-or-refresh-dv-table"
  description       = "Python script uses Boto3-Athena-Client to run sql-statements"
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  default_arguments = {
    "--parquet_output_bucket_name"       = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"             = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"            = "glue_df_output"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.create_or_refresh_dv_table[0].name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/create_or_refresh_dv_table.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Py script as glue-job that creates dv table / refreshes its partitions",
    }
  )

}


resource "aws_cloudwatch_log_group" "dms_dv_on_rows_hashvalue_partitionby_yyyy_mm" {
  count             = local.is-production || local.is-development ? 1 : 0
  name              = "dms-dv-on-rows-hashvalue-partitionby-yyyy-mm"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_s3_object" "dms_dv_on_rows_hashvalue_partitionby_yyyy_mm" {
  count       = local.is-production || local.is-development ? 1 : 0
  bucket      = module.s3-glue-job-script-bucket.bucket.id
  key         = "dms_dv_on_rows_hashvalue_partitionby_yyyy_mm.py"
  source      = "glue-job/dms_dv_on_rows_hashvalue_partitionby_yyyy_mm.py"
  source_hash = filemd5("glue-job/dms_dv_on_rows_hashvalue_partitionby_yyyy_mm.py")
}

resource "aws_glue_job" "dms_dv_on_rows_hashvalue_partitionby_yyyy_mm" {
  count = local.gluejob_count

  name              = "dms-dv-on-rows-hashvalue-partitionby-yyyy-mm"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                  = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                      = split(":", aws_db_instance.database_2022[0].endpoint)[0]
    "--rds_db_pwd"                          = aws_db_instance.database_2022[0].password
    "--rds_database_folder"                 = ""
    "--rds_db_schema_folder"                = "dbo"
    "--rds_table_orignal_name"              = ""
    "--table_pkey_column"                   = ""
    "--date_partition_column_name"          = ""
    "--rds_hashed_rows_prq_parent_dir"      = "rds_tables_rows_hashed"
    "--dms_prq_output_bucket"               = module.s3-dms-target-store-bucket.bucket.id
    "--dms_prq_table_folder"                = ""
    "--rds_only_where_clause"               = ""
    "--prq_df_where_clause"                 = ""
    "--skip_columns_for_hashing"            = ""
    "--read_rds_tbl_agg_stats_from_parquet" = "false"
    "--rds_hashed_rows_prq_bucket"          = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_dv_bucket"              = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"                = aws_glue_catalog_database.dms_dv_glue_catalog_db[0].name
    "--glue_catalog_tbl_name"               = "glue_df_output"
    "--extra-py-files"                      = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder[0].id}"
    "--continuous-log-logGroup"             = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_on_rows_hashvalue_partitionby_yyyy_mm[0].name}"
    "--enable-continuous-cloudwatch-log"    = "true"
    "--enable-continuous-log-filter"        = "true"
    "--enable-metrics"                      = "true"
    "--enable-auto-scaling"                 = "true"
    "--conf"                                = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=512m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection[0].name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_on_rows_hashvalue_partitionby_yyyy_mm.py"
  }
  security_configuration = aws_glue_security_configuration.em_glue_security_configuration[0].name

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}
