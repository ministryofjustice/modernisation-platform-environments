# Authorizor lambda

Usage:

```
module "data_product_authorizer_lambda" {
  source = "./modules/authorizor_lambda"
  environment = local.environment
  api_resource_arn = aws_api_gateway_rest_api.data_platform.execution_arn
  api_source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*"
  tags = local.tags
}
```