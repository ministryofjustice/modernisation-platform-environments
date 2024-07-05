# 4. Glue Job(s) - TODO

resource "aws_glue_job" "rds_to_parquet_chunkwise_job" {
  name        = "rds_to_parquet_chunkwise"
  description = "ELM-2342 Data Validation Glue-Job (PySpark) Spike."
  role_arn    = aws_iam_role.dms_dv_glue_job_iam_role.arn # Change this to created one?

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/rds_to_parquet_chunkwise.py"
    python_version  = "3"
  }

  default_arguments = {
    "--script_bucket_name"                = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                  = ""
    "--parquet_output_bucket_name"        = aws_s3_bucket.dms_dv_parquet_s3_bucket.id # change
    #"--enable-continuous-cloudwatch-log"  = "true"
    #"--enable-continuous-log-filter"      = "true"
    #"--enable-metrics"                    = "true"
    #"--enable-auto-scaling"               = "true"
  }

  glue_version = "4.0"
  max_retries  = 1
  timeout      = 10000
}

resource "aws_glue_job" "simple_data_validation_of_parquet_job" {
  name        = "simple_data_validation_of_parquet"
  description = "ELM-2342 Data Validation Glue-Job (PySpark) Spike."
  role_arn    = aws_iam_role.dms_dv_glue_job_iam_role.arn # Change this to created one?

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.dms_dv_glue_job_s3_bucket.id}/rds_to_parquet_chunkwise.py"
    python_version  = "3"
  }

  default_arguments = {
    "--script_bucket_name"                = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
    "--rds_db_host_ep"                    = split(":", aws_db_instance.database_2022.endpoint)[0]
    "--rds_db_pwd"                        = aws_db_instance.database_2022.password
    "--rds_sqlserver_db"                  = ""
    "--parquet_src_bucket_name"           = aws_s3_bucket.dms_target_ep_s3_bucket.id # change
    "--parquet_output_bucket_name"        = aws_s3_bucket.dms_dv_parquet_s3_bucket.id # change
    #"--enable-continuous-cloudwatch-log"  = "true"
    #"--enable-continuous-log-filter"      = "true"
    #"--enable-metrics"                    = "true"
    #"--enable-auto-scaling"               = "true"
  }

  glue_version = "4.0"
  max_retries  = 1
  timeout      = 10000
}