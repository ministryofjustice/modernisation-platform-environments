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
# DMS Validation Step Function
# ------------------------------------------

module "dms_validation_step_function" {
  source       = "./modules/step_function"
  name         = "dms_validation_${locals.environment_shorthand}"
  iam_policies = tomap({ "dms_validation_step_function_policy" = aws_iam_policy.dms_validation_step_function_policy })
  variable_dictionary = tomap(
    {
      "dms_validation_lambda" = module.dms_validation.lambda_function_name,
    }
  )
  type = "EXPRESS"
}

