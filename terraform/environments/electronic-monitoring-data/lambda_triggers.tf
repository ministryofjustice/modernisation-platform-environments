module "calculate_checksum_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  s3_suffixes          = [
    ".bak",
    ".zip",
    ".bacpac",
    ".7z",
    ".xlsx",
    ".gz",
    ".csv",
  ]
  lambda_function_name = module.calculate_checksum.lambda_function_name
}

module "format_json_fms_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  s3_prefix            = "serco/fms/"
  s3_suffixes          = [".JSON"]
  lambda_function_name = module.format_json_fms_data.lambda_function_name
}

module "copy_mdss_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  s3_prefix            = "serco/fms/"
  s3_suffixes          = [".JSON"]
  lambda_function_name = module.copy_mdss_data.lambda_function_name
}
