#### This file can be used to store locals specific to the member account ####
locals {
  # Lambda
  lambda_runtime            = "python3.9"
  lambda_timeout_in_seconds = 15
  name                      = "data-platform-product"

  # Glue
  glue_version                     = "4.0"
  max_retries                      = 0
  worker_type                      = "G.1X"
  number_of_workers                = 2
  timeout                          = 120 # minutes
  execution_class                  = "STANDARD"
  max_concurrent                   = 5
  glue_log_group_retention_in_days = 7
}
