#### This file can be used to store locals specific to the member account ####
locals {

  ##
  # Variables code_extractor lambda
  ##
  code_function_name               = "code_extractor"
  code_function_handler            = "main.handler"
  code_function_runtime            = "python3.9"
  code_function_timeout_in_seconds = 15

  code_function_source_dir = "${path.module}/src/${local.code_function_name}"

  ##
  # Variables data_extractor lambda
  ##
  data_function_name               = "data_extractor"
  data_function_handler            = "main.handler"
  data_function_runtime            = "python3.9"
  data_function_timeout_in_seconds = 15

  data_function_source_dir = "${path.module}/src/${local.data_function_name}"

  ##
  # Variables for glue job
  ##
  glue_default_arguments = {
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
    "--enable-job-insights"              = "true"
    "--enable-continuous-log-filter"     = "true"
  }

  name                             = "data-platform-product"
  glue_version                     = "4.0"
  max_retries                      = 0
  worker_type                      = "G.1X"
  number_of_workers                = 2
  timeout                          = 120 # minutes
  execution_class                  = "STANDARD"
  max_concurrent                   = 5
  glue_log_group_retention_in_days = 7
}
