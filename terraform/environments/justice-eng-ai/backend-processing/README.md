# backend-processing

Terraform for the AI Application Builder backend: the Step Functions workflows, the script-runner ECS tasks that run the platform scripts, and the notifications and monitoring around them. Workflow definitions use the shared `../modules/step_function_builder` module. Step Functions and script-runner IAM permissions are centralised in `step_functions_common.tf` and `ecs_script_runner.tf`.

## Workflows

| File | State machine | Purpose |
|---|---|---|
| `step_functions_root.tf` | root | Looks up the build, then runs the control plane, image build, prototype deployment and notification |
| `step_functions_control_plane.tf` | control-plane | Reviews the request (Bedrock) and waits for approval if needed |
| `step_functions_build_image.tf` | build-app-image | Builds the prototype image (`build-prototype-image.py`) |
| `step_functions_deploy_prototype.tf` | deploy-prototype | Deploys the prototype. Dev and prod only |
| `step_functions_notify.tf` | notify | Emails the user and sends the Slack job-completion alert |

### Prototype deployment

`prototype_deployment.py` runs once per stage, in this order: `table`, `task_definition`, `target_group`, `listener_rule`, `service`, `dns`.

- `table` creates a DynamoDB table `prototype-<request id>` (key `pk`, pay-per-request, encrypted, TTL on `expiresAt`).
- All prototypes share the `<app>-prototype-app-task` role (`ecs_script_runner.tf`), passed as `TASK_ROLE_ARN`. It can only read and write `table/prototype-*`.
- The script-runner task role can create and describe those tables, set their TTL and tag them, and pass the prototype task role.
- The `dns` stage returns `url` (full `https://<host><entry path>`), `host`, `entry_path` and `dns_change_id`. They end up under `$.dns` in the execution output, and the notify state machine reads `$.dns.url`.

### Notifications

- The email goes through GOV.UK Notify. A separate copy goes to the Modernisation Platform mailbox, sent first.
- The Slack alert is published to the `<app>-job-completion` SNS topic (KMS encrypted) and delivered by AWS Chatbot.
- Inputs come from `application_variables.json`: `notify_template_id`, `slack_channel_id` and `builder_hostname`.

## Slack channels

Both use `modernisation-platform-terraform-aws-chatbot` v3.0.0, pinned to its commit SHA in `slack_notifications.tf`. The Slack client must be set up manually in each account first. Nothing is created while a channel ID is empty.

| Variable | Receives |
|---|---|
| `slack_channel_id` | Job-completion messages (`<app>-job-completion` topic) |
| `alerts_slack_channel_id` | Alarms and runtime errors (`<app>-alerts` topic) |

## Monitoring

All alarms publish to the encrypted `<app>-alerts` topic and are named `<app>-<environment>-...`. Alarm thresholds are counts within a 5 minute period unless stated.

`monitoring.tf`:

- **Script-runner hard errors:** `entrypoint.sh` logs a JSON `script_runner_hard_error` line when a script exits non-zero. A metric filter and alarm count them. The script-runner image must be rebuilt for the line to appear.
- **Step Functions:** one alarm per state machine for failed, timed-out or aborted executions.
- **Task failed to start:** an EventBridge rule sends script-runner `TaskFailedToStart` events to Slack.
- **Bedrock (logs):** metric filters on the control-plane (script-runner) and web-ui ECS logs for `throttled`, `timeout`, `token-limit` and `failed` errors, each with its own alarm. The filters match exception names and message text, so adjust them if the application's log wording changes.
- **Bedrock (service):** alarms on the `AWS/Bedrock` throttle, client-error and server-error metrics for the configured model.

`monitoring_runtime.tf` (dev and prod, where the web UI and prototype stack are deployed):

- **Load balancers:** 5xx, target 5xx, target connection errors, rejected connections and unhealthy hosts for the web-ui and prototype ALBs. The unhealthy-host alarm uses Metrics Insights across every target group, so it covers prototypes created at runtime.
- **Web UI service:** no running tasks, CPU and memory above 85%, and ERROR-level log lines.
- **ECS events:** service errors, failed deployments and unexpected task stops for the web-ui and prototype clusters.
- **DynamoDB:** system errors and throttling across all tables in the account.

The web-ui log group and load balancer are looked up by name, so apply the `web-ui` and `prototypes-infra` roots first.

Not covered: the forge runner's Bedrock calls, EFS, and per-prototype log groups.
