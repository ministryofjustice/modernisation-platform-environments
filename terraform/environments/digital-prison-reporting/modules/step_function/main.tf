resource "aws_sfn_state_machine" "data_ingestion_step_function" {
  count = var.enable_step_function ? 1 : 0

  name     = var.step_function_name
  role_arn = aws_iam_role.step_function_role[0].arn

  definition = var.definition
}