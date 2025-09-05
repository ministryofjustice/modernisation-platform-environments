resource "aws_cloudwatch_event_target" "definition_update" {
  rule      = aws_cloudwatch_event_rule.definition_update.name
  target_id = "definition-update"
  arn       = module.virus_scan_definition_upload.lambda_function_arn
}


resource "aws_cloudwatch_event_target" "dms_validation_step_function_trigger" {
  count      = local.is-production || local.is-development ? 1 : 0
  rule       = aws_cloudwatch_event_rule.dms_task_completed[0].name
  arn        = module.dms_validation_step_function[0].arn
  role_arn   = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role[0].arn
  input_path = "$"
}