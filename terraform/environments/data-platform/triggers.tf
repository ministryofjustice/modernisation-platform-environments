
resource "aws_cloudwatch_event_rule" "object_created_raw_data" {
  name = "object_created_raw_data"
  tags = local.tags
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [module.data_s3_bucket.bucket.id] },
      "object" : {
        "key" : [{ "prefix" : "raw_data/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "object_created_data_landing" {
  name = "object_created_raw_data"
  tags = local.tags
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [module.data_s3_bucket.bucket.id] },
      "object" : {
        "key" : [{ "prefix" : "raw_data/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "athena_load_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.object_created_raw_data.name
  target_id = "athena"
  arn       = module.data_product_athena_load_lambda.lambda_function_arn
}

resource "aws_cloudwatch_event_target" "athena_load_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.object_created_raw_data.name
  target_id = "athena"
  arn       = module.data_product_athena_load_lambda.lambda_function_arn
}
