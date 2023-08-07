
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