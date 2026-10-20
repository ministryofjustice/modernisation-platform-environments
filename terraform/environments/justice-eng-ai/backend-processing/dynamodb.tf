locals {
  build_review_table_name = "${local.application_name}-build-details"

  # The counter is an item in the table: AppID plus this SysKey, holding the latest SysKey in this attribute.
  build_counter_sys_key   = 0
  build_counter_attribute = "LastSysKey"
}

# Build events. Each status change is a new item and nothing is updated in place.
#   AppID  (S) hash key: groups every event for an application.
#   SysKey (N) range key: increases with each event for the AppID, so a Query on
#              AppID lists the events in order (ScanIndexForward=false for latest first).
# Writers get the next SysKey by atomically incrementing the counter item
# (AppID, SysKey = 0, attribute LastSysKey) with UpdateItem ADD, then PutItem the event
# with UserName, AppID, BuildID, JobStage, JobStatus and Date. Queries listing events
# should filter SysKey > 0 to skip the counter item.
# The awaiting_approval event also holds a TaskToken, used to resume the paused
# execution. It must not be exposed to the UI: grant the UI role only the display
# attributes (dynamodb:Attributes with dynamodb:Select = SPECIFIC_ATTRIBUTES) and have
# its queries use ProjectionExpression.
resource "aws_dynamodb_table" "build_review" {
  name         = local.build_review_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AppID"
  range_key    = "SysKey"

  attribute {
    name = "AppID"
    type = "S"
  }

  attribute {
    name = "SysKey"
    type = "N"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.tags
}
