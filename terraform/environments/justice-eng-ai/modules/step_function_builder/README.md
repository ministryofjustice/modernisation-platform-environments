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
    task_definition_family = local.script_runner_task_definition_family
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

## Notes on `input_path` and payload size

`input_path` selects a single JSONPath from the current state and passes it as
the whole `Input` for the child execution; it does not merge or reshape
fields from multiple locations. Step Functions caps state input/output at
256 KB, and this cap applies to the accumulated state, not just the original
request payload.

When `result_path` is used (recommended over letting a step's result replace
the whole state), each step's output is added under its own key rather than
overwriting prior data. If a later step then sets `input_path = "$"`, it
forwards the *entire* accumulated history of every previous step's result,
not just the data it actually needs. In a long chain of `step_function`
steps this can grow the payload unnecessarily and risks exceeding the 256 KB
limit, even when the real data the child needs is small.

Prefer scoping `input_path` to the specific prior result a child state
machine actually needs, e.g. `input_path = "$.previous_step_name"`, rather
than defaulting to `"$"` for every step. This also makes the dependency
between steps explicit and self-documenting.

This only works when a step needs data from one contiguous location. If a
child genuinely needs fields from more than one earlier step's result, a
single `input_path` cannot compose them. Options in that case are to nest
the required reference inside the result of the step immediately before it
(so it becomes reachable via one path), or to have the calling environment
pass only lightweight references (IDs, S3 bucket/key) end-to-end rather than
the full payload, with each step resolving data itself from the referenced
location (e.g. S3) instead of relying on Step Functions to carry it.

This module intentionally keeps `input_path` as a single, generic JSONPath
rather than a named-parameter list: the actual input shape is specific to
each calling environment, not something the module should assume.