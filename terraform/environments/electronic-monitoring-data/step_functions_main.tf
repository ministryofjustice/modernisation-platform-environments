# ------------------------------------------
# Fake Athena Layer
# ------------------------------------------

module "athena_layer" {
  source       = "./modules/step_function"
  name         = "athena_layer"
  iam_policies = tomap({ "lambda_invoke_policy" = aws_iam_policy.lambda_invoke_policy })
  variable_dictionary = tomap({
    get_metadata_lambda_arn = module.get_metadata_from_rds_lambda.lambda_function_arn
    create_athena_table     = module.create_athena_table.lambda_function_arn
  })
}


# ------------------------------------------
# Send Database to AP
# ------------------------------------------

module "send_database_to_ap" {
  source       = "./modules/step_function"
  name         = "send_database_to_ap"
  iam_policies = tomap({ "send_database_to_ap" = aws_iam_policy.send_database_to_ap })
  variable_dictionary = tomap({
    athena_workgroup        = aws_athena_workgroup.default.name
    query_output_to_list    = module.query_output_to_list.lambda_function_arn
    get_file_keys_for_table = module.get_file_keys_for_table.lambda_function_arn
    send_table_to_ap        = module.send_table_to_ap.lambda_function_arn
    update_log_table        = module.update_log_table.lambda_function_arn
  })
}

# ------------------------------------------
# Unzip Files
# ------------------------------------------

module "get_zipped_file" {
  source       = "./modules/step_function"
  name         = "get_zipped_file"
  iam_policies = tomap({ "trigger_unzip_lambda" = aws_iam_policy.trigger_unzip_lambda })
  variable_dictionary = tomap(
    {
      "unzip_file_name"            = module.unzip_single_file.lambda_function_name,
      "pre_signed_url_lambda_name" = module.unzipped_presigned_url.lambda_function_name
    }
  )
  type = "EXPRESS"
}
