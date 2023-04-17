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
}
