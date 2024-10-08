resource "aws_sfn_state_machine" "data_ingestion_step_function" {
  count = var.enable_step_function ? 1 : 0

  name     = var.step_function_name
  role_arn = var.step_function_execution_role_arn

  definition = var.definition

  tags = var.tags
}