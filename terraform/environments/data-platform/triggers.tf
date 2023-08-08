
resource "aws_cloudwatch_event_rule" "object_created_raw_data" {
  name = "object_created_raw_data"
  tags = local.tags
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [module.s3-bucket.bucket.id] },
      "object" : {
        "key" : [{ "prefix" : "raw_data/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "athena_load_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.object_created_raw_data.name
  target_id = "athena"
  arn       = aws_lambda_function.athena_load.arn
}
