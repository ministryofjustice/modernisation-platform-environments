resource "aws_sfn_state_machine" "data_ingestion_step_function" {
  count = var.enable_step_function ? 1 : 0

  name     = var.step_function_name
  role_arn = var.step_function_execution_role_arn

  tracing_configuration {
    enabled = true
  }

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step-function-log-group[count.index].arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  definition = var.definition

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.step-function-log-group
  ]
}

### Step function log group
resource "aws_cloudwatch_log_group" "step-function-log-group" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for time being in view of Cost Savings”
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"

  count = var.enable_step_function ? 1 : 0
  name  = "/aws/vendedlogs/states/log-group-${var.step_function_name}"

  retention_in_days = var.step_function_log_retention_in_days

  tags = merge(
    var.tags,
    {
      name = "log-group-${var.step_function_name}"
      Jira = "DPR2-1857"
  })
}