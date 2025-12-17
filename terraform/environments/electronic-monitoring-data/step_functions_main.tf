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
  count = local.is-development || local.is-production ? 1 : 0

  source       = "./modules/step_function"
  name         = "dms_validation"
  iam_policies = tomap({ "dms_validation_step_function_policy" = aws_iam_policy.dms_validation_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "dms_retrieve_metadata" = module.dms_retrieve_metadata[0].lambda_function_name,
      "dms_validation"        = module.dms_validation[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Historic Data Cut Back Step Function
# ------------------------------------------

module "historic_data_cutback_step_function" {
  count = local.is-development || local.is-production ? 1 : 0

  source       = "./modules/step_function"
  name         = "historic_data_cutback"
  iam_policies = tomap({ "historic_data_cutback_step_function_policy" = aws_iam_policy.historic_data_cutback_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "historic_data_cutback" = module.historic_data_cutback[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}
