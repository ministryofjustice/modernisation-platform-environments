# resource "aws_s3_object" "dms_dv_rds_and_s3_parquet_write_v2" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "dms_dv_rds_and_s3_parquet_write_v2.py"
#   source = "glue-job/dms_dv_rds_and_s3_parquet_write_v2.py"
#   etag   = filemd5("glue-job/dms_dv_rds_and_s3_parquet_write_v2.py")
# }


# resource "aws_s3_object" "dms_dv_rds_and_s3_parquet_write_v4d" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "dms_dv_rds_and_s3_parquet_write_v4d.py"
#   source = "glue-job/dms_dv_rds_and_s3_parquet_write_v4d.py"
#   etag   = filemd5("glue-job/dms_dv_rds_and_s3_parquet_write_v4d.py")
# }


# resource "aws_s3_object" "rds_to_s3_parquet_migration_monthly" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "rds_to_s3_parquet_migration_monthly.py"
#   source = "glue-job/rds_to_s3_parquet_migration_monthly.py"
#   etag   = filemd5("glue-job/rds_to_s3_parquet_migration_monthly.py")
# }


# resource "aws_s3_object" "rds_to_s3_parquet_migration" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "rds_to_s3_parquet_migration.py"
#   source = "glue-job/rds_to_s3_parquet_migration.py"
#   etag   = filemd5("glue-job/rds_to_s3_parquet_migration.py")
# }


# resource "aws_s3_object" "resizing_parquet_files" {
#   bucket = module.s3-glue-job-script-bucket.bucket.id
#   key    = "resizing_parquet_files.py"
#   source = "glue-job/resizing_parquet_files.py"
#   etag   = filemd5("glue-job/resizing_parquet_files.py")
# }


# resource "aws_cloudwatch_log_group" "dms_dv_cw_log_group_v2" {
#   name              = "dms-dv-glue-job-v2"
#   retention_in_days = 14
# }


# resource "aws_cloudwatch_log_group" "rds_to_s3_parquet_migration" {
#   name              = "rds-to-s3-parquet-migration"
#   retention_in_days = 14
# }


# resource "aws_cloudwatch_log_group" "resizing_parquet_files" {
#   name              = "resizing-parquet-files"
#   retention_in_days = 14
# }
# -------------------------------------------------------------------

# resource "aws_glue_job" "dms_dv_glue_job_v2" {
#   name              = "dms-dv-glue-job-v2"
#   description       = "DMS Data Validation Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 8
#   default_arguments = {
#     "--script_bucket_name"                = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
#     "--rds_db_pwd"                        = aws_db_instance.database_2022.password
#     "--rds_sqlserver_db"                  = ""
#     "--rds_sqlserver_db_schema"           = "dbo"
#     "--rds_exclude_db_tbls"               = ""
#     "--rds_select_db_tbls"                = ""
#     "--rds_db_tbl_pkeys_col_list"         = ""
#     "--rds_df_trim_str_columns"           = "false"
#     "--rds_df_trim_micro_sec_ts_col_list" = ""
#     "--rds_read_rows_fetch_size"          = 50000
#     "--num_of_repartitions"               = 0
#     "--read_partition_size_mb"            = 128
#     "--max_table_size_mb"                 = 4000
#     "--parquet_tbl_folder_if_different"   = ""
#     "--parquet_src_bucket_name"           = module.s3-dms-target-store-bucket.bucket.id
#     "--parquet_output_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
#     "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
#     "--glue_catalog_tbl_name"             = "glue_df_output"
#     "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_cw_log_group_v2.name}"
#     "--enable-continuous-cloudwatch-log"  = "true"
#     "--enable-continuous-log-filter"      = "true"
#     "--enable-metrics"                    = "true"
#     "--enable-auto-scaling"               = "true"
#     "--conf"                              = <<EOF
# spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
# --conf spark.sql.parquet.aggregatePushdown=true 
# --conf spark.sql.files.maxPartitionBytes=128m 
# EOF

#   }

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_and_s3_parquet_write_v2.py"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }
# # Note: Make sure 'max_table_size_mb' and 'spark.sql.files.maxPartitionBytes' values are the same.

# # "--enable-spark-ui"                   = "false"
# # "--spark-ui-event-logs-path"          = "false"
# # "--spark-event-logs-path"             = "s3://${module.s3-glue-job-script-bucket.bucket.id}/spark_logs/"


# resource "aws_glue_job" "dms_dv_glue_job_v4d" {
#   name              = "dms-dv-glue-job-v4d"
#   description       = "DMS Data Validation Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.dms_dv_glue_job_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.2X"
#   number_of_workers = 5
#   default_arguments = {
#     "--script_bucket_name"                = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
#     "--rds_db_pwd"                        = aws_db_instance.database_2022.password
#     "--prq_leftanti_join_rds"             = "false"
#     "--parquet_df_repartition_num"        = 32
#     "--parallel_jdbc_conn_num"            = 4
#     "--rds_df_repartition_num"            = 16
#     "--rds_upperbound_factor"             = 8
#     "--rds_sqlserver_db"                  = ""
#     "--rds_sqlserver_db_schema"           = "dbo"
#     "--rds_sqlserver_db_table"            = ""
#     "--rds_db_tbl_pkeys_col_list"         = ""
#     "--rds_df_trim_str_columns"           = "false"
#     "--rds_df_trim_micro_sec_ts_col_list" = ""
#     "--parquet_src_bucket_name"           = module.s3-dms-target-store-bucket.bucket.id
#     "--parquet_output_bucket_name"        = module.s3-dms-data-validation-bucket.bucket.id
#     "--glue_catalog_db_name"              = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
#     "--glue_catalog_tbl_name"             = "glue_df_output"
#     "--continuous-log-logGroup"           = "/aws-glue/jobs/${aws_cloudwatch_log_group.dms_dv_cw_log_group.name}"
#     "--enable-continuous-cloudwatch-log"  = "true"
#     "--enable-continuous-log-filter"      = "true"
#     "--enable-metrics"                    = "true"
#     "--enable-auto-scaling"               = "true"
#     "--conf"                              = <<EOF
# spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
# --conf spark.sql.parquet.aggregatePushdown=true 
# --conf spark.sql.shuffle.partitions=2001 
# --conf spark.sql.files.maxPartitionBytes=1g 
# EOF

#   }

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/dms_dv_rds_and_s3_parquet_write_v4d.py"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }


# resource "aws_glue_job" "rds_to_s3_parquet_migration" {
#   name              = "rds-to-s3-parquet-migration"
#   description       = "Table migration & validation Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 5
#   default_arguments = {
#     "--script_bucket_name"                   = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                       = split(":", aws_db_instance.database_2022.endpoint)[0]
#     "--rds_db_pwd"                           = aws_db_instance.database_2022.password
#     "--rds_sqlserver_db"                     = ""
#     "--rds_sqlserver_db_schema"              = "dbo"
#     "--rds_sqlserver_db_table"               = ""
#     "--rds_query_where_clause"               = ""
#     "--rds_db_tbl_pkeys_col_list"            = ""
#     "--rds_table_total_size_mb"              = 0
#     "--rds_df_repartition_num"               = 0
#     "--date_partition_column_name"           = ""
#     "--other_partitionby_columns"            = ""
#     "--validation_sample_fraction_float"     = 0
#     "--validation_sample_df_repartition_num" = 0
#     "--jdbc_read_256mb_partitions"           = "false"
#     "--jdbc_read_512mb_partitions"           = "false"
#     "--jdbc_read_1gb_partitions"             = "false"
#     "--jdbc_read_2gb_partitions"             = "false"
#     "--default_jdbc_read_partition_num"      = 1
#     "--rename_migrated_prq_tbl_folder"       = ""
#     "--year_partition_bool"                  = "false"
#     "--month_partition_bool"                 = "false"
#     "--validation_only_run"                  = "false"
#     "--rds_df_filter_year"                   = 0
#     "--rds_df_filter_month"                  = 0
#     "--rds_to_parquet_output_s3_bucket"      = module.s3-dms-target-store-bucket.bucket.id
#     "--dv_parquet_output_s3_bucket"          = module.s3-dms-data-validation-bucket.bucket.id
#     "--glue_catalog_db_name"                 = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
#     "--glue_catalog_tbl_name"                = "glue_df_output"
#     "--continuous-log-logGroup"              = "/aws-glue/jobs/${aws_cloudwatch_log_group.rds_to_s3_parquet_migration.name}"
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

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/rds_to_s3_parquet_migration.py"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }



# resource "aws_glue_job" "rds_to_s3_parquet_migration_monthly" {
#   name              = "rds-to-s3-parquet-migration-monthly"
#   description       = "Table migration Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 5
#   default_arguments = {
#     "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
#     "--rds_db_host_ep"                   = split(":", aws_db_instance.database_2022.endpoint)[0]
#     "--rds_db_pwd"                       = aws_db_instance.database_2022.password
#     "--rds_sqlserver_db"                 = ""
#     "--rds_sqlserver_db_schema"          = "dbo"
#     "--rds_sqlserver_db_table"           = ""
#     "--rds_query_where_clause"           = ""
#     "--rds_db_tbl_pkeys_col_list"        = ""
#     "--date_partition_column_name"       = ""
#     "--other_partitionby_columns"        = ""
#     "--default_jdbc_read_partition_num"  = 1
#     "--rds_df_repartition_num"           = 0
#     "--coalesce_int"                     = 0
#     "--rename_migrated_prq_tbl_folder"   = ""
#     "--year_partition_bool"              = "false"
#     "--month_partition_bool"             = "false"
#     "--rds_to_parquet_output_s3_bucket"  = module.s3-dms-target-store-bucket.bucket.id
#     "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.rds_to_s3_parquet_migration.name}"
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

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/rds_to_s3_parquet_migration_monthly.py"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }


# resource "aws_glue_job" "resizing_parquet_files" {
#   name              = "resizing-parquet-files"
#   description       = "Table migration & validation Glue-Job (PySpark)."
#   role_arn          = aws_iam_role.glue_mig_and_val_iam_role.arn
#   glue_version      = "4.0"
#   worker_type       = "G.1X"
#   number_of_workers = 5
#   default_arguments = {
#     "--script_bucket_name"               = module.s3-glue-job-script-bucket.bucket.id
#     "--s3_prq_read_db_folder"            = ""
#     "--s3_prq_read_db_schema_folder"     = "dbo"
#     "--s3_prq_read_table_folder"         = ""
#     "--s3_prq_write_table_folder"        = ""
#     "--primarykey_column"                = ""
#     "--date_partition_column"            = ""
#     "--s3_prq_read_where_clause"         = ""
#     "--year_int_filter"                  = 0
#     "--month_int_filter"                 = 0
#     "--prq_df_repartition_int"           = 0
#     "--coalesce_int"                     = 0
#     "--year_bool_partition"              = "true"
#     "--month_bool_partition"             = "true"
#     "--day_bool_partition"               = "false"
#     "--s3_prq_read_bucket_name"          = module.s3-dms-target-store-bucket.bucket.id
#     "--s3_prq_write_bucket_name"         = module.s3-dms-target-store-bucket.bucket.id
#     "--continuous-log-logGroup"          = "/aws-glue/jobs/${aws_cloudwatch_log_group.resizing_parquet_files.name}"
#     "--enable-continuous-cloudwatch-log" = "true"
#     "--enable-continuous-log-filter"     = "true"
#     "--enable-metrics"                   = "true"
#     "--enable-auto-scaling"              = "true"
#     "--conf"                             = <<EOF
# spark.sql.legacy.parquet.datetimeRebaseModeInRead=CORRECTED 
# --conf spark.sql.sources.partitionOverwriteMode=dynamic 
# --conf spark.sql.parquet.aggregatePushdown=true 
# --conf spark.sql.files.maxPartitionBytes=512m 
# EOF

#   }

#   connections = [aws_glue_connection.glue_rds_sqlserver_db_connection.name]
#   command {
#     python_version  = "3"
#     script_location = "s3://${module.s3-glue-job-script-bucket.bucket.id}/resizing_parquet_files.py"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "Glue-Job that processes data sourced from both RDS and S3",
#     }
#   )

# }
