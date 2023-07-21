data "aws_iam_policy_document" "iam_policy_document_for_presigned_url_lambda" {
  statement {
    sid       = "GetPutDataObject"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${module.s3-bucket.bucket.arn}/raw_data/*"]
  }
}

module "data_product_presigned_url_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.1"
  application_name               = "data_product_presigned_url"
  tags                           = local.tags
  description                    = "Lambda to generate a presigned url for uploading data"
  role_name                      = "presigned_url_lambda_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_presigned_url_lambda.json
  function_name                  = "data_product_presigned_url_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-presigned-url-lambda-ecr-repo:1.0.0"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action        = "lambda:InvokeFunction"
      function_name = "data_product_presigned_url_${local.environment}"
      principal     = "apigateway.amazonaws.com"
      source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.upload_data_get.http_method}${aws_api_gateway_resource.upload_data.path}"
    }
  }

}

output "presigned_url_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, aws_api_gateway_stage.sandbox.stage_name, "/presigned_url/"])
}
