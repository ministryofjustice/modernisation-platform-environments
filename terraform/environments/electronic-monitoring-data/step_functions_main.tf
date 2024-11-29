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
# Unzip Files
# ------------------------------------------

module "get_zipped_file_api" {
  source       = "./modules/step_function"
  name         = "get_zipped_file_api"
  iam_policies = tomap({ "trigger_unzip_lambda" = aws_iam_policy.trigger_unzip_lambda })
  variable_dictionary = tomap(
    {
      "unzip_file_name"            = module.unzip_single_file.lambda_function_name,
      "pre_signed_url_lambda_name" = module.unzipped_presigned_url.lambda_function_name
    }
  )
  type = "EXPRESS"
}

# ------------------------------------------
# Regenerate JSONL data
# ------------------------------------------

module "regenerate_jsonl" {
  source       = "./modules/step_function"
  name         = "regenerate_jsonl"
  iam_policies = tomap({ "regenerate_jsonl_policy" = aws_iam_policy.regenerate_jsonl_policy })
  variable_dictionary = tomap({
    "source_bucket_name"           = module.s3-data-bucket.bucket_name
    "atrium_directory"             = "g4s/atrium_unstructured/"
  })

}