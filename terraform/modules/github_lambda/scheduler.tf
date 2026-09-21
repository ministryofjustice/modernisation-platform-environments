resource "aws_scheduler_schedule" "github_workflow" {
  for_each = var.github_workflows

  name = "${var.project_name}-${each.key}"

  schedule_expression          = each.value.schedule
  schedule_expression_timezone = each.value.timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.github_workflow_trigger.arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    input = jsonencode({
      inputs   = each.value.inputs
      org      = var.github_org
      ref      = each.value.ref
      repo     = each.value.repo
      workflow = each.value.workflow
    })
  }
}
