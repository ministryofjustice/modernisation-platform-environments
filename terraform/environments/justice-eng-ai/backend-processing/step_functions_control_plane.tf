locals {
  control_plane_state_machine_name = "${local.application_name}-control-plane"

  control_plane_steps = [
    {
      name        = "run_control_plane"
      type        = "script_runner"
      script_path = "scripts/control/root.py"
      shell_type  = "python3"
      variables = [
        { name = "s3_folder", path = "$.s3_folder" },
        { name = "s3_file", path = "$.s3_file" },
        { name = "AppID", path = "$.AppID" },
        { name = "forge_runtime_version", path = "$.forge_runtime_version" },
      ]
      result_path = "$.control_plane_task"
    }
  ]
}

module "step_functions_control_plane" {
  source = "../modules/step_function_builder"

  step_function_retry_attempts = local.step_function_retry_attempts

  name               = local.control_plane_state_machine_name
  steps              = local.control_plane_steps
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