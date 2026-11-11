resource "aws_lambda_permission" "schema_registration_s3" {
  count = local.registration_enabled ? 1 : 0

  statement_id  = "AllowContractBucketRegistration"
  action        = "lambda:InvokeFunction"
  function_name = module.schema_registration[0].function_name
  principal     = "s3.amazonaws.com"

  source_arn     = aws_s3_bucket.contract_management["contracts"].arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "contracts" {
  count = local.registration_enabled ? 1 : 0

  bucket = aws_s3_bucket.contract_management["contracts"].id

  dynamic "lambda_function" {
    for_each = local.registration_contract_prefixes

    content {
      id = "register-${substr(sha256(lambda_function.value), 0, 16)}"

      lambda_function_arn = module.schema_registration[0].function_arn
      events              = ["s3:ObjectCreated:*"]

      filter_prefix = lambda_function.value
      filter_suffix = ".avsc"
    }
  }

  depends_on = [
    aws_lambda_permission.schema_registration_s3,
  ]
}
