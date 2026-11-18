# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

CloudWatch alarms for script-runner failures, Bedrock errors, failed Step Functions executions and web UI or prototype runtime problems post to the Slack alerts channel (`alerts_slack_channel_id` in `application_variables.json`). See [backend-processing/README.md](backend-processing/README.md).

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

#### Builder team authorisation behind the ALB

The web-ui account setting `alb_group_authorization_enabled` defaults to
false. The companion application change must be available before enabling
it. The configuration enables **development, test and production**.
Development team members have confirmed reviewer access, and a review action
has succeeded. Test and production require their own deployment and acceptance
checks; enabling the account settings does not prove live access.

Enabling it adds `offline_access` and delegated Microsoft Graph `User.Read` to the ALB OIDC
scopes and sets `MPAPB_ALB_GROUP_AUTHORIZATION_ENABLED=true` on the builder
task definition. The application binds the forwarded access token to the
ALB-signed subject through Microsoft UserInfo, then checks the configured
admin/reviewer group IDs using Graph. The same group intentionally grants
both roles. No tenant-wide Graph application permissions are required.

Entra v2 requires an explicit `offline_access` request to issue refresh
tokens. The ALB uses that refresh token to renew access tokens during its
12-hour session; the session timeout does not extend an access token's
lifetime. Invalid Graph tokens still fail closed.

#### Coordinated UI releases

The UI uses the same SHA-tagged build across all three environments via
the shared `var.container_image_tag` default: `ui-build-f0a35e6`, from commit
`f0a35e6804e78defdb3cca6bb503e52f6522f267`. Its UI authentication tests and
image build passed in [application workflow run 40671475362](https://github.com/ministryofjustice/modernisation-platform-ai-application-builder/actions/runs/40671475362).
The existing build workflow already publishes SHA tags; no build changes
are needed. Automated promotion following the script-runner pattern is a
separate follow-up, with no release SSM parameters added here. Do not
overwrite SHA tags; record actual running image digests after deployment.
SHA naming alone does not enforce registry immutability.

Terraform manages the UI service's task definition and waits for steady
state. An approved web-ui apply now deploys the image and the complete
authentication configuration together; it no longer only registers an
unused revision. The ECS deployment circuit breaker retains automatic
rollback on deployment failure. Desired count remains operator-managed.
Forge retains its existing CI/CD deployment behaviour.

The application repository's image deployment workflow can still update
the UI service outside Terraform. Do not approve competing UI releases
during this rollout. Such updates appear as task-definition drift on the
next Terraform plan, which will restore the Terraform task definition and
configuration. For later releases, update the shared `container_image_tag`
default in a reviewed PR to promote the selected build across all three
environments. Publishing a new `ui-build-latest` image does not change this
Terraform release selection. Do not assume an image-only deployment imports
the newest Terraform settings.

Rollout order:

Pull requests run plans only for every environment. Deployments start from
the main-branch workflow after merge (or an explicit main-branch deployment
dispatch), retaining the existing environment approval protections. Do not
approve superseded pre-merge apply jobs from older workflow runs.

1. Add delegated Graph `User.Read` to the Entra app registration and arrange
   consent under tenant policy. This repository does not manage Entra.
2. Verify the linked build checks and confirm all three plans select
   `ui-build-f0a35e6`, not `ui-build-latest`.
3. Review each account's web-ui Terraform plan. Expect a new UI task
   definition and an actual service task-definition update. All accounts
   must use `MPAPB_TRUST_ALB_OIDC=true`, `MPAPB_ENTRA_ENABLED=false`,
   `MPAPB_ALB_GROUP_AUTHORIZATION_ENABLED=true`, the configured group IDs and
   their own ALB signer ARN. Expect the listener scopes to include both
   `https://graph.microsoft.com/User.Read` and `offline_access`. Compare
   against live state; test has been reported working with the feature
   enabled outside the merged configuration. Review unrelated drift separately.
4. Record each service's current task-definition revision and listener scopes
   for rollback. Production was running revision 15 during inspection on
   28 October 2026; that is the previous state, not a known-working sign-in
   configuration. Apply each environment's reviewed web-ui plan through its
   approved workflow. The apply rolls the UI service onto the new task
   definition and waits for stability; no manual revision cloning is needed.
5. Start a fresh ALB login with consent to the new scope. Existing ALB
   sessions may lack `User.Read` or a refresh token. Refresh the session once
   by removing only that site's `AWSELBAuthSessionCookie*` cookies and reloading.
   Clearing the HTTP cache or closing the browser does not reliably renew
   an ALB session.
6. Verify `/auth/user` includes the configured group, `/whoami` returns
   reviewer status, and review read/write access works for team members.
   Verify non-members are denied, Graph errors fail closed, and membership
   removal is reflected after Graph propagation and the 60-second cache.
7. Prefer completing test acceptance before deploying production. Repeat the
   plan, apply, ECS rollout and acceptance checks for production; do not assume
   test results validate production.
8. Verify access after the original access token expires without deleting
   cookies or signing out. Entra tokens typically last around 60–90 minutes;
   immediate successful login is not proof of renewal. Record login and
   later successful request times, never tokens. If Graph 401 recurs,
   investigate ALB authentication and application Graph logs rather than
   treating repeated cookie deletion as the solution. Renewal remains
   unverified until this live acceptance check passes.

Graph availability is required for authenticated dynamic pages while
enabled. Health checks, assets and logout bypass membership lookup.
UserInfo/token identity mismatch gives 401; Graph service or permission
errors give 503. No tokens should be copied to logs, tickets or chat.
For an emergency rollback, switch the affected service to a recorded
compatible task-definition revision using its recorded image digest or
commit tag, not the mutable `latest` tag. Reconcile the Terraform image
setting and configuration in a PR before the next apply, otherwise Terraform
restores its configured release. To disable group checks, disable the account
setting and apply the reviewed listener and UI task-definition changes together; this
restores allow-list-only ALB access. Do not restore an in-app task behind an
authenticating ALB: production revision 15 has that mismatch and can restore
the sign-in loop rather than working access.

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

#### ECS task CPU and memory settings

Builder and Forge task sizes and the Forge capacity limits are set per environment in
`web-ui/application_variables.json`. The `web-ui` root reads that file, not the
`application_variables.json` in this folder (which `backend-processing` reads). The values are
read without fallbacks, so a missing key fails the plan.

| Key | Used by | Effect | development / test | production |
| --- | --- | --- | --- | --- |
| `builder_task_cpu` | Builder task definition | Fargate CPU units | 512 | 2048 |
| `builder_task_memory` | Builder task definition | Fargate memory (MiB) | 1024 | 4096 |
| `forge_task_cpu` | Forge task definition | Fargate CPU units | 2048 | 2048 |
| `forge_task_memory` | Forge task definition | Fargate memory (MiB); also sets the Node heap | 8192 | 8192 |
| `forge_max_builds_in_memory` | Forge `FORGE_MAX_BUILDS_IN_MEMORY` | Builds kept in memory before the least recently used is evicted | 200 | 200 |
| `forge_design_check_concurrency` | Forge `DESIGN_CHECK_CONCURRENCY` | Chromium design checks that run at once; the rest queue | 3 | 3 |
| `forge_design_check_queue_timeout_ms` | Forge `DESIGN_CHECK_QUEUE_TIMEOUT_MS` | Time a design check may wait in the queue | 120000 | 120000 |

- The Forge Node heap (`NODE_OPTIONS=--max-old-space-size`) is derived in `forge-journey-lab.tf`
  as 75% of `forge_task_memory`, so it follows the memory setting.
- Fargate only accepts certain CPU and memory pairs, and Terraform does not check them. For
  example 2048 CPU requires 4096 to 16384 MiB.
- Forge runs as a single task. Sessions and build state live in the task and on EFS, so it
  cannot be scaled out horizontally; increase these values instead. Builder holds no
  server-side session state.
- A Builder change takes effect once the `web-ui` plan is applied in that environment. Confirm
  the plan shows a new task definition revision for the service.
- The Forge service ignores `task_definition` changes (`forge-journey-lab.tf`) so an apply can
  never move it back to an older revision or image. A Forge size or environment change
  therefore applies in two steps:
  1. Apply `web-ui`. It registers a new `forge-journey-lab` revision but leaves the service on
     its current one.
  2. Run the Forge deploy (`deploy-ecs.yml` in the application repository). It clones the
     latest revision of the family, so it picks up Terraform's CPU, memory and environment,
     swaps in the new image and moves the service. This restarts Forge and ends active sessions.
- The image tag is held in the SSM parameter
  `/modernisation-platform-ai-builder-core/forge/container-image-tag` (`web-ui/parameters.tf`).
  Terraform creates it once from `forge_container_image_tag` and then ignores its value. The
  deploy workflow writes the tag it deployed, and Terraform reads it, so Terraform-registered
  revisions always carry the deployed image. This is the same pattern as the script-runner
  image tag in `backend-processing/parameters.tf`.
- To check a Forge size, look at the task definition revision the service is running, not only
  the newest revision of the family.

### **Scheduled environment wipe (development and test only):**

The `<application>-wipe-environment` state machine (`backend-processing/step_functions_wipe_environment.tf`,
built with `modules/step_function_builder`) deletes all data so the environment is clean again. It runs
`scripts/maintenance/wipe_environment.py` from the application repository in a dedicated script-runner task.

- **Settings**, in the root `application_variables.json` under the environment:

  | Key | Meaning |
  | --- | --- |
  | `environment_wipe_enabled` | `true` turns the schedule on; `false` creates it disabled (it can still be started by hand) |
  | `environment_wipe_schedule` | EventBridge cron expression with six fields, evaluated in UK time, e.g. `cron(0 2 ? * SUN *)` (Sundays 02:00) or `cron(0 2 ? * MON-FRI *)` (weekdays 02:00) |
  | `environment_wipe_efs` | `true` also empties the web UI file system (Builder and Forge files) |

  Development is set to Sundays at 02:00 and test to every night at 02:00 (`cron(0 2 * * ? *)`), both with the file system included. **Preproduction and
  production have none of these keys, so nothing is created there.** The plan fails if the keys are
  added to those environments, and the script refuses to run unless `ENVIRONMENT` is `development`
  or `test`.
- **What it does**, in order: scales Builder and Forge to zero; stops running executions of the
  other state machines; deletes all prototype resources (ECS services, task definitions, target
  groups, listener rules, log groups, tables, DNS records); deletes every item in every other
  DynamoDB table (including the build counters, so numbering restarts at 1), every image in the
  user-applications ECR repository and every S3 object version in the staging bucket; purges the
  approval dead-letter queue; empties the file system (top-level directories are kept); then
  restores Builder and Forge to their previous task counts, also when a step fails. Builder and
  Forge are down for the duration. They have to be: Forge holds an index of the file system in
  memory and would write stale data back if it kept running.
- **Alarms**: where the schedule is enabled, the alarm mute rule
  `justice-eng-ai-<environment>-wipe-window` mutes the Builder and Forge alarms (web UI no running
  tasks, web UI unhealthy hosts and the web UI load balancer alarms) from 00:00 to 04:00 UK time.
  The alarms are still evaluated; one that is still in ALARM at 04:00 notifies then. The schedule
  must start between 00:00 and 02:59, and the plan fails otherwise.
- The shared script-runner image in `modernisation-platform-ai-builder-core` is not touched.
- The script is baked into the script-runner image, so after changing it run the
  `script-runner-image-build` workflow. It registers a new revision of the wipe task definition
  where the family exists and skips it where it does not (production).
- Run it by hand with Start execution on the state machine (input `{}`). Alerts for a failed
  wipe come from the common state-machine failure alarm.

### **Scheduled prototype expiry:**

The `<application>-expire-prototypes` state machine (`backend-processing/step_functions_expire_prototypes.tf`,
built with `modules/step_function_builder`) removes dormant prototypes: those whose image has not been redeployed for a set number of
days. It runs `scripts/maintenance/expire_prototypes.py` from the application repository in a dedicated
script-runner task.

- **Settings**, in the root `application_variables.json` under the environment:

  | Key | Meaning |
  | --- | --- |
  | `prototype_expiry_enabled` | `true` turns the schedule on; `false` creates it disabled (it can still be started by hand) |
  | `prototype_expiry_schedule` | EventBridge cron expression with six fields, evaluated in UK time, e.g. `cron(0 3 * * ? *)` (every night at 03:00) |
  | `prototype_expiry_max_age_days` | Whole number of days. Prototypes whose current image was deployed more than this many days ago are removed |

  Nothing is created for an environment without `prototype_expiry_schedule`. It is enabled in development
  and test and created disabled in preproduction and production, all at 03:00 with a 30-day limit.
- **What it does**: lists the `prototype-*` services in the prototype cluster and picks those whose current image
  was deployed (the service's PRIMARY deployment) more than the limit ago. Every redeploy resets the
  age, so prototypes still being worked on are kept and dormant ones are removed. For each, it reads the full AppID from the
  image tag and deletes, in order: the `<AppID>-<BuildID>` images in the user-applications ECR
  repository, every version of the `<AppID>` packages in the staging bucket, the AppID's items in the
  build-details table (including its build counter), its DNS record, its listener rules, its prototype
  DynamoDB table, its ECS service, its target group, its task definitions and its log group. The web UI
  file system (EFS) is not mounted and Builder and Forge keep running.
- **Deletion log**: one JSON line per prototype (AppID, deployment date, age and counts of what was
  deleted, or the error) plus a run summary, in a stream per run in the `/<application>/prototype-expiry`
  log group, kept for 10 years.
- **Report**: a message listing the removed AppIDs (and any failures) is posted to `slack_channel_id`
  through the job-completion topic after every run, including runs that remove nothing.
- A failure on one prototype does not stop the others. The run then fails, so the common state-machine
  failure alarm fires, and the next run picks the prototype up again.
- The script is baked into the script-runner image, so after changing it run the
  `script-runner-image-build` workflow. It registers a new revision of the expiry task definition where
  the family exists and skips it where it does not.
- Run it by hand with Start execution on the state machine (input `{}`).

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
