# Step Function Builder

The module creates a Standard Step Functions state machine from an ordered list of steps. Declare the list in a local in the calling environment and pass the shared execution role from `step_functions_common.tf`.

Each step is either:

- `script_runner`: requires `name`, `type = "script_runner"`, `script_path`, and `shell_type`. Optional `variables` is a list of `{ name, value }` or `{ name, path }` objects. `path` reads from the current Step Functions input.
- `step_function`: requires `name`, `type = "step_function"`, and `state_machine_name`. Optional `input_path` selects the input passed to the child workflow. The module builds the ARN using the current account and region.

The first list item starts the process; subsequent items run in list order. Both step types support optional `retry`, `timeout_seconds`, and `result_path` attributes. Set `result_path` when a step should preserve the current input while storing its result.

## Example 1: ECS Script

```hcl
locals {
  process_steps = [
    {
      name        = "Validate request"
      type        = "script_runner"
      script_path = "scripts/your-script.sh"
      shell_type  = "bash"
      variables = [
        { name = "REQUEST_ID", path = "$.request_id" },
        { name = "MODE", value = "strict" },
      ]
      result_path = "$.results.validation"
    },
  ]
}

module "script_runner_process" {
  source             = "./modules/step_function_builder"
  name               = "${local.application_name}-process"
  steps              = local.process_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  script_runner = {
    cluster_arn         = aws_ecs_cluster.script_runner.arn
    task_definition_arn = aws_ecs_task_definition.script_runner.arn
    container_name      = "script-runner"
    subnets             = module.vpc.private_subnets
    security_groups     = [aws_security_group.script_runner_task.id]
    assign_public_ip    = "DISABLED"
    execution_role_arn  = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn       = aws_iam_role.script_runner_ecs_task.arn
  }
  tags               = local.tags

  depends_on = [aws_iam_role_policy.step_functions_common]
}
```

Replace `scripts/your-script.sh` with a path present in the built image. The caller supplies execution input fields used by `path` variables, such as `request_id` above.

## Example 2: Child Step Function

This example runs a child state machine by name and waits for it to finish. Its name must start with `${local.application_name}-` to match the shared role's permissions.

```hcl
locals {
  process_steps = [
    {
      name               = "Run child process"
      type               = "step_function"
      state_machine_name = "${local.application_name}-child-process"
      input_path         = "$"
      result_path        = "$.results.child_process"
    },
  ]
}

module "child_process" {
  source             = "./modules/step_function_builder"
  name               = "${local.application_name}-child-wrapper"
  steps              = local.process_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  tags               = local.tags

  depends_on = [aws_iam_role_policy.step_functions_common]
}
```