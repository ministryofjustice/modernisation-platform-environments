# Step Function Builder

The module creates a Standard Step Functions state machine from an ordered list of steps. Declare the list in a local in the calling environment and pass the shared execution role from `step_functions_common.tf`.

Each step is either:

- `script_runner`: requires `name`, `type = "script_runner"`, `script_path`, and `shell_type`. Optional `variables` is a list of `{ name, value }` or `{ name, path }` objects. `path` reads from the current Step Functions input.
- `step_function`: requires `name`, `type = "step_function"`, and `state_machine_name`. Optional `input_path` selects the input passed to the child workflow. The module builds the ARN using the current account and region.

- `dynamodb_get_item`: requires `name`, `type = "dynamodb_get_item"`, `table_name` and `key` (attribute name => JSONPath or intrinsic function giving its string value). Optional `result_attributes` returns those string attributes at the top level of the result; without it the raw `{ Item = {...} }` result is returned, with no `Item` when nothing exists. Reads natively through Step Functions, with no Lambda.
- `choice`: requires `name`, `type = "choice"`, `variable`, and either `equals` or `when_absent = true`. Execution continues to the next step when the string at `variable` equals `equals` (or, with `when_absent`, when `variable` is absent); otherwise it ends successfully at `<name>_stop` (optional `stop_comment`). It cannot be the last step.

The first list item starts the process; subsequent items run in list order. Both step types support optional `retry`, `timeout_seconds`, and `result_path` attributes. Set `result_path` when a step should preserve the current input while storing its result.

Choose a `script_runner.task_definition_family` that matches `launch_type`.
Fargate task definitions must use `awsvpc` networking and cannot use host
volumes; EC2 task definitions can use host networking and host volumes. Supply
the `ec2` host configuration only for EC2 workflows.

## Script runtime failures and retries

Both Fargate and EC2 script steps inspect the completed container's exit code.
A non-zero or missing exit code reruns only that script step, waiting 15 seconds
between executions. `step_function_retry_attempts` defaults to 3 additional executions
(four executions in total); set it to 0 to disable reruns. The counter resets
for each script step. EC2 retries reuse the dedicated host and clean it up after
success or exhausted retries. Exhaustion fails the workflow with
`ScriptRunnerFailed` and includes the final ECS task result in the failure cause.

Scripts must propagate failures as a non-zero process exit status (for example,
uncaught Python exceptions or explicit Bash `exit 1`). Printed error messages or
JSON on stdout alone are not interpreted as failures. Scripts must be safe to
rerun after partial work. Existing step-level `retry` settings handle ECS/API
task failures separately; they do not override the script exit-code retry limit.

In justice-eng-ai, set `accounts.<environment>.step_function_retry_attempts` in
`application_variables.json`. The backend-processing workflows pass this setting
to the module, falling back to 3 when the key is absent.

The justice-eng-ai control-plane workflow runs `scripts/control/root.py`. The
script writes a record to the build review DynamoDB table (`dynamodb.tf`), keyed
by `AppID` (the `s3_file` basename), only when the automated assessment flags the
request for review. The workflow then looks the record up. The root workflow
continues to the post-approval workflow (image build, then infrastructure) only
when no record exists, i.e. the request was approved automatically. A request
with a record waits in the table with status `not approved`; when a reviewer sets
it to `approved`, an EventBridge Pipe on the table's stream
(`eventbridge_pipes.tf`) starts the post-approval workflow with the record's
`AppID`, `s3_folder` and `s3_file`. `AppID` and `forge_runtime_version` for the
later steps are derived in Terraform, not returned by the script.

## Parent fallback cleanup for EC2 children

On a `step_function` step, set
`ec2_cleanup = { managed_by = "your-disposable-host-tag" }` when its child uses
this module's disposable EC2 runtime. The justice-eng-ai root enables this for
the image-build child only.

The parent adds the reserved `__script_runner_root_execution_arn` field to the
selected child input, which must be a JSON object. Application fields are
otherwise preserved. The child tags its instances with `RootExecutionArn`
alongside the existing `BuildExecutionArn` and `ManagedBy` tags. Standalone
EC2 executions use their own execution ARN as the root tag. The parent reserves
`script_runner_child` in its own state for input preparation and cleanup.
This helper starts with a letter to avoid leading-underscore JSONPath parsing
issues in intrinsic function arguments.

After the nested Task's configured retries are exhausted, its `Catch` waits
30 seconds for in-flight launches to become visible and discovers hosts matching
both the root execution ARN and the configured `ManagedBy` tag. It terminates
them, polling every 30 seconds for up to 40 checks per host, then queries again
for remaining hosts. Empty results are safe, including when the child already
cleaned up. Successful cleanup fails the parent with the original child error;
cleanup failure reports `ChildInstanceCleanupFailed` with both errors.
Normal child cleanup also polls until termination before continuing.

This fallback covers a child failing before reaching its own cleanup, including
child runtime errors. It cannot run if the parent itself is stopped or times
out, and is not an external orphan-instance sweeper. Previously launched hosts
without the new root tag are not discovered. EC2 API errors and visibility
delays can still prevent cleanup and must be investigated when reported.
The shared execution role needs `ec2:DescribeInstances` and tag-scoped
`ec2:TerminateInstances`; justice-eng-ai already grants these in
`step_functions_common.tf`. No Lambda or additional execution role is needed.

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