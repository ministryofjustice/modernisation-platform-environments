resource "aws_cloudwatch_event_rule" "dms_task_completed" {
    name = var.event_bridge_rule_name
    description = "Triggeres DMS validation Step Function"

    event_pattern = jsonencode({
        "source": ["aws.dms"],
        "detail-type": ["DMS Replication Task State Change"],
        "detail": {
            "SourceIdentifier" : ["${replace(var.database_name, "_", "-")}-db-migration-task-tf"],
            "EventID": ["DMS-EVENT-0079"],
            "EventMessage": ["Replication task has stopped. Stop Reason ${var.dms_trigger_state}"]
        }
    })
}

resource "aws_cloudwatch_event_target" "dms_validation_step_function_trigger" {
    rule = aws_cloudwatch_event_rule.dms_task_completed.name
    arn = var.dms_validation_step_function_arn
    role_arn = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role.arn
    input_path = "$"
}
