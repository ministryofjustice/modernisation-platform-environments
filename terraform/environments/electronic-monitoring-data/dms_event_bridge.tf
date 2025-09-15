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

resource "aws_cloudwatch_event_target" "dms_validation_step_function_trigger" {
  count      = local.is-production || local.is-development ? 1 : 0
  rule       = aws_cloudwatch_event_rule.dms_task_completed[0].name
  arn        = module.dms_validation_step_function[0].arn
  role_arn   = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role[0].arn
  input_path = "$"
}
