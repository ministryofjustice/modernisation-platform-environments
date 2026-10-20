locals {
  build_infra_state_machine_name = "${local.application_name}-build-app-infra"

  build_infra_steps = [
    {
      name        = "build_app_infra"
      type        = "script_runner"
      script_path = "scripts/deployment/root.py"
      shell_type  = "python3"
      variables = [
        { name = "AppID", path = local.script_runner_app_id_path },
        { name = "BuildID", path = "$.latest.BuildID" },
        { name = "forge_runtime_version", value = local.script_runner_forge_runtime_version },
        { name = "REVIEW_TABLE_NAME", value = aws_dynamodb_table.build_review.name },
        { name = "AWS_REGION", value = local.aws_region },
      ]
      result_path = "$.build_infra_task"
    }
  ]
}

module "step_functions_build_infra" {
  source = "../modules/step_function_builder"

  step_function_retry_attempts = local.step_function_retry_attempts

  name               = local.build_infra_state_machine_name
  steps              = local.build_infra_steps
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