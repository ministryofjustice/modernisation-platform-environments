resource "aws_cloudwatch_event_rule" "definition_update" {
  name                = "definition-update"
  schedule_expression = "cron(15 6 * * ? *)" # 06:15 every day
}

resource "aws_cloudwatch_event_rule" "dms_task_completed" {
  count       = local.is-production || local.is-development ? 1 : 0
  name        = "dms_validation_trigger_rule"
  description = "Triggeres DMS validation Step Function"

  event_pattern = jsonencode({
    "source" : ["aws.dms"],
    "detail-type" : ["DMS Replication Task State Change"],
    "detail" : {
      "eventId" : ["DMS-EVENT-0079"],
      "eventType" : ["REPLICATION_TASK_STOPPED"]
      "detailMessage" : ["Stop Reason FULL_LOAD_ONLY_FINISHED"]
    }
  })
}
