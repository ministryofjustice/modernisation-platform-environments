# Create DMS Endpoint to RDS Source
resource "aws_dms_endpoint" "dms-rds-conn-tf" {

    #   certificate_arn             = ""
    database_name               = var.database_name
    endpoint_id                 = "rds-mssql-${var.database_name}-tf"
    endpoint_type               = "source"
    engine_name                 = "sqlserver"
    #   extra_connection_attributes = ""
    #   kms_key_arn                 = aws_db_instance.database_2022.kms_key_id
    password                    = var.rds_db_instance_pasword # aws_db_instance.database_2022.password
    port                        = var.rds_db_instance_port # aws_db_instance.database_2022.port
    server_name                 = var.rds_db_server_name # split(":", aws_db_instance.database_2022.endpoint)[0]
    ssl_mode                    = "require"
    username                    = var.rds_db_username # aws_db_instance.database_2022.username

    # tags = merge(
    #   local.tags,
    #   {
    #     Resource_Type = "DMS Source Endpoint - RDS MSSQL",
    #   }
    # )
}

# ==========================================================================

# Create DMS Endpoint to S3 Target
resource "aws_dms_s3_endpoint" "dms-s3-csv-tf" {
  
  # Minimal Config:
  endpoint_id                      = "s3-${var.database_name}-tf"
  endpoint_type                    = "target"
  bucket_name                      = data.aws_s3_bucket.existing_dms_bucket.id
  service_access_role_arn          = aws_iam_role.dms-endpoint-role.arn
  
  # Extra settings:
  # add_column_name                             = false
  # add_trailing_padding_character              = false
  bucket_folder                                 = var.database_name
  # canned_acl_for_objects                      = "NONE"
  # cdc_inserts_and_updates                     = false
  # cdc_inserts_only                            = false
  # cdc_max_batch_interval                      = 60
  # cdc_min_file_size                           = 32000
  # cdc_path                                    = "cdc/path"
  # compression_type                            = "NONE"
  # csv_delimiter                               = ","
  # csv_no_sup_value                            = "false"
  # csv_null_value                              = "null"
  # csv_row_delimiter                           = "\\n"
  data_format                                 = "csv"
  # data_page_size                              = 1100000
  # date_partition_delimiter                    = "UNDERSCORE"
  # date_partition_enabled                      = false
  # date_partition_sequence                     = "yyyymmddhh"
  # date_partition_timezone                     = "Europe/London"
  # dict_page_size_limit                        = 1000000
  # enable_statistics                           = true
  # encoding_type                               = "plain"
  # encryption_mode                             = "SSE_S3"
  # expected_bucket_owner                       = data.aws_caller_identity.current.account_id
  # external_table_definition                   = "meta"
  # glue_catalog_generation                     = true
  # ignore_header_rows                          = 1
  # include_op_for_full_load                    = true
  # max_file_size                               = 120000
  # parquet_timestamp_in_millisecond            = false
  # parquet_version                             = "parquet-2-0"
  # preserve_transactions                       = false
  # rfc_4180                                    = false
  # row_group_length                            = 11000
  # server_side_encryption_kms_key_id           = aws_kms_key.example.arn
  # timestamp_column_name                       = "_timestamp"
  # use_csv_no_sup_value                        = false
  # use_task_start_time_for_full_load_timestamp = true

  # depends_on = [aws_iam_policy.dms-s3-ep-iam-role-policy]
  
  # tags = merge(
  #   local.tags,
  #   {
  #     Resource_Type = "DMS Target Endpoint - S3",
  #   }
  # )

}