#### This file can be used to store locals specific to the member account ####
locals {

  ##
  # Variables code_extractor lambda
  ##
  function_name               = "code_extractor"
  function_handler            = "main.handler"
  function_runtime            = "python3.9"
  function_timeout_in_seconds = 15

  function_source_dir = "${path.module}/src/${local.function_name}"
}
