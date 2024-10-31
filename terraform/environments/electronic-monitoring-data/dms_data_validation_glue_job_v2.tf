resource "aws_s3_object" "aws_s3_object_pyzipfile_to_s3folder" {
  bucket = module.s3-glue-job-script-bucket.bucket.id
  key    = "${var.s3_pylib_dir_path}/glue_data_validation_lib.zip"
  source = data.archive_file.archive_file_zip_py_files.output_path
  acl    = "private"
  etag   = filemd5(data.archive_file.archive_file_zip_py_files.output_path)
}

# resource "aws_lakeformation_resource" "lf_register_dms_dv_glue_catalog_db_data_location" {
#   arn = module.s3-dms-data-validation-bucket.bucket.arn
# }

# resource "aws_lakeformation_permissions" "aws_lf_permissions_data_location_access" {
#   principal   = aws_iam_role.lakeformation_dataaccess_role.arn
#   permissions = ["DATA_LOCATION_ACCESS"]

#   data_location {
#     arn =  module.s3-dms-data-validation-bucket.bucket.arn
#   }

#   depends_on = [aws_lakeformation_resource.lf_register_dms_dv_glue_catalog_db_data_location]
# }

resource "aws_glue_catalog_database" "dms_dv_glue_catalog_db" {
  name = "dms_data_validation"

  create_table_default_permission {
    permissions = ["ALL"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

# resource "aws_glue_catalog_table" "glue_df_output" {
#   name          = "glue_df_output"
#   database_name = aws_glue_catalog_database.dms_dv_glue_catalog_db.name

#   table_type = "EXTERNAL_TABLE"

#   parameters = {
#     EXTERNAL              = "TRUE"
#     classification        = "parquet"
#     "parquet.compression" = "SNAPPY"
#   }

#   storage_descriptor {
#     location      = "s3://${module.s3-dms-data-validation-bucket.bucket.id}/${aws_glue_catalog_database.dms_dv_glue_catalog_db.name}/glue_df_output"
#     input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
#     output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

#     ser_de_info {
#       name                  = "my-stream"
#       serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

#       parameters = {
#         "serialization.format" = 1
#       }
#     }

#     columns {
#       name = "run_datetime"
#       type = "timestamp"
#     }

#     columns {
#       name = "json_row"
#       type = "string"
#     }

#     columns {
#       name    = "validation_msg"
#       type    = "string"
#       comment = ""
#     }

#     columns {
#       name    = "my_bigint"
#       type    = "string"
#       comment = ""
#     }

#   }

#   partition_keys {
#     name = "database_name"
#     type = "string"
#   }

#   partition_keys {
#     name = "full_table_name"
#     type = "string"
#   }

# }


resource "aws_cloudwatch_log_group" "dms_dv_rds_to_s3_parquet_v1" {
  name              = "dms-dv-rds-to-s3-parquet-v1"
  retention_in_days = 14
}


resource "aws_s3_object" "dms_dv_rds_to_s3_parquet_v1" {
  bucket = module.s3-glue-job-script-bucket.bucket.id
  key    = "dms_dv_rds_to_s3_parquet_v1.py"
  source = "glue-job/dms_dv_rds_to_s3_parquet_v1.py"
  etag   = filemd5("glue-job/dms_dv_rds_to_s3_parquet_v1.py")
}


resource "aws_glue_job" "dms_dv_rds_to_s3_parquet_v1" {
  name              = "dms-dv-rds-to-s3-parquet_v1"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                  = ""
    "--rds_sqlserver_db_schema"           = "dbo"
    "--rds_exclude_db_tbls"               = ""
    "--rds_select_db_tbls"                = ""
    "--rds_db_tbl_pkeys_col_list"         = ""
    "--rds_df_trim_str_columns"           = "false"
    "--rds_df_trim_micro_sec_ts_col_list" = ""
    "--num_of_repartitions"               = 0
    "--read_partition_size_mb"            = 128
    "--max_table_size_mb"                 = 4000
    "--parquet_tbl_folder_if_different"   = ""
    "--extra-py-files"                    = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder.id}"
    "--parquet_src_bucket_name"           = module.s3-dms-target-store-bucket.bucket.id
    "--parquet_output_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"             = "glue_df_output"
    "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_rds_to_s3_parquet_v1.name}"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true"
    "--enable-metrics"                    = "true"
    "--enable-auto-scaling"               = "true"
    "--conf"                              = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=128m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_to_s3_parquet_v1.py"
  }

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
  name              = "dms-dv-rds-to-s3-parquet-v2"
  retention_in_days = 14
}


resource "aws_s3_object" "dms_dv_rds_to_s3_parquet_v2" {
  bucket = module.s3-glue-job-script-bucket.bucket.id
  key    = "dms_dv_rds_to_s3_parquet_v2.py"
  source = "glue-job/dms_dv_rds_to_s3_parquet_v2.py"
  etag   = filemd5("glue-job/dms_dv_rds_to_s3_parquet_v2.py")
}


resource "aws_glue_job" "dms_dv_rds_to_s3_parquet_v2" {
  name              = "dms-dv-rds-to-s3-parquet-v2"
  description       = "DMS Data Validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
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
    "--extra-py-files"                    = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder.id}"
    "--parquet_src_bucket_name"           = module.s3-dms-target-store-bucket.bucket.id
    "--parquet_output_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"             = "glue_df_output"
    "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_rds_to_s3_parquet_v2.name}"
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

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_to_s3_parquet_v2.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}


resource "aws_cloudwatch_log_group" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
  name              = "etl-rds-to-s3-parquet-partitionby-yyyy-mm"
  retention_in_days = 14
}


resource "aws_s3_object" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
  bucket = module.s3-glue-job-script-bucket.bucket.id
  key    = "etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  source = "glue-job/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  etag   = filemd5("glue-job/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py")
}


resource "aws_glue_job" "etl_rds_to_s3_parquet_partitionby_yyyy_mm" {
  name              = "etl-rds-to-s3-parquet-partitionby-yyyy-mm"
  description       = "Table migration Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                       = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                 = ""
    "--rds_sqlserver_db_schema"          = "dbo"
    "--rds_sqlserver_db_table"           = ""
    "--rds_query_where_clause"           = ""
    "--rds_db_tbl_pkeys_col_list"        = ""
    "--date_partition_column_name"       = ""
    "--other_partitionby_columns"        = ""
    "--jdbc_read_partition_num"          = 1
    "--rds_df_repartition_num"           = 0
    "--coalesce_int"                     = 0
    "--rename_migrated_prq_tbl_folder"   = ""
    "--year_partition_bool"              = "false"
    "--month_partition_bool"             = "false"
    "--extra-py-files"                   = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder.id}"
    "--rds_to_parquet_output_s3_bucket"  = module.s3-dms-target-store-bucket.bucket.id
    "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_rds_to_s3_parquet_partitionby_yyyy_mm.name}"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-auto-scaling"              = "true"
    "--conf"                             = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}


resource "aws_cloudwatch_log_group" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
  name              = "etl-dv-rds-to-s3-parquet-partitionby-yyyy-mm"
  retention_in_days = 14
}

resource "aws_s3_object" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
  bucket = module.s3-glue-job-script-bucket.bucket.id
  key    = "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  source = "glue-job/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  etag   = filemd5("glue-job/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py")
}

resource "aws_glue_job" "etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm" {
  name              = "etl-dv-rds-to-s3-parquet-partitionby-yyyy-mm"
  description       = "Table migration & validation Glue-Job (PySpark)."
  role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 4
  default_arguments = {
    "--script_bucket_name"                   = module.s3-glue-job-script-bucket.bucket.id
    "--rds_db_host_ep"                       = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                           = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                     = ""
    "--rds_sqlserver_db_schema"              = "dbo"
    "--rds_sqlserver_db_table"               = ""
    "--rds_query_where_clause"               = ""
    "--rds_db_tbl_pkeys_col_list"            = ""
    "--rds_table_total_size_mb"              = 0
    "--rds_df_repartition_num"               = 0
    "--date_partition_column_name"           = ""
    "--other_partitionby_columns"            = ""
    "--validation_sample_fraction_float"     = 0
    "--validation_sample_df_repartition_num" = 0
    "--jdbc_read_256mb_partitions"           = "false"
    "--jdbc_read_512mb_partitions"           = "false"
    "--jdbc_read_1gb_partitions"             = "false"
    "--jdbc_read_2gb_partitions"             = "false"
    "--jdbc_read_partition_num"              = 1
    "--rename_migrated_prq_tbl_folder"       = ""
    "--year_partition_bool"                  = "false"
    "--month_partition_bool"                 = "false"
    "--validation_only_run"                  = "false"
    "--rds_df_year_int_equals_to"            = 0
    "--rds_df_month_int_equals_to"           = 0
    "--extra-py-files"                       = "s3://${module.s3-glue-job-script-bucket.bucket.id}/${aws_s3_object.aws_s3_object_pyzipfile_to_s3folder.id}"
    "--rds_to_parquet_output_s3_bucket"      = module.s3-dms-target-store-bucket.bucket.id
    "--dv_parquet_output_s3_bucket"          = module.s3-dms-data-validation-bucket.bucket.id
    "--glue_catalog_db_name"                 = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
    "--glue_catalog_tbl_name"                = "glue_df_output"
    "--continuous-log-logGroup"              = "/aws-glue/jobs/${aws_cloudwatch_log_group.etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.name}"
    "--enable-continuous-cloudwatch-log"     = "true"
    "--enable-continuous-log-filter"         = "true"
    "--enable-metrics"                       = "true"
    "--enable-auto-scaling"                  = "true"
    "--conf"                                 = <<EOF
spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
--conf spark.sql.sources.partitionOverwriteMode=dynamic 
--conf spark.sql.parquet.aggregatePushdown=true 
--conf spark.sql.files.maxPartitionBytes=256m 
EOF

  }

  connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
  command {
    python_version  = "3"
    script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/etl_dv_rds_to_s3_parquet_partitionby_yyyy_mm.py"
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
    }
  )

}
