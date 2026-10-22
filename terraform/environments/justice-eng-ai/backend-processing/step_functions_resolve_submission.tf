locals {
  resolve_submission_state_machine_name = "${local.application_name}-resolve-submission"
  resolve_submission_steps = [{
    name        = "resolve_submission"
    type        = "script_runner"
    script_path = "scripts/submission/resolve.py"
    shell_type  = "python3"
    variables = [
      { name = "S3_BUCKET", value = aws_s3_bucket.staging_bucket.id },
      { name = "S3_KEY", path = "$.s3_file" },
      { name = "SOURCE_EVENT", path = "States.JsonToString($)" },
      { name = "REVIEW_TABLE_NAME", value = aws_dynamodb_table.build_review.name },
      { name = "AWS_REGION", value = data.aws_region.current.region },
    ]
    result_path     = "$.submission"
    timeout_seconds = 300
    outputs         = true
  }]
}

module "step_functions_resolve_submission" {
  source = "../modules/step_function_builder"

  step_function_retry_attempts = local.step_function_retry_attempts

  name               = local.resolve_submission_state_machine_name
  steps              = local.resolve_submission_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  script_runner = {
    cluster_arn            = aws_ecs_cluster.script_runner.arn
    task_definition_family = local.script_runner_fargate_task_definition_family
    container_name         = "script-runner"
    subnets                = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
    security_groups        = [aws_security_group.script_runner_task.id]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn          = aws_iam_role.script_runner_ecs_task.arn
    launch_type            = "FARGATE"
  }
  tags = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    aws_iam_role_policy_attachment.script_runner_ecs_task,
    aws_iam_role_policy_attachment.script_runner_ecs_execution,
    aws_ecs_task_definition.script_runner_fargate,
  ]
}
