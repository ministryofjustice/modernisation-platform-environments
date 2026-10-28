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

The UI uses `ui-build-latest` as an intermediate release approach via
`var.container_image_tag`. Automated commit-SHA promotion, following the
script-runner pattern, is a separate follow-up; this change adds no release
SSM parameters or application workflow changes. The tag is mutable: freeze
competing image publications during this rollout and record the actual
running image digest per environment afterward. The same tag does not
guarantee the same image if its value changes between deployments.

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
configuration. Publishing a new image under `ui-build-latest` alone does not
update existing tasks or create a Terraform diff. Later image releases
still need an explicit service deployment. Do not assume an image-only
deployment imports the newest Terraform settings.

Rollout order:

Pull requests run plans only for every environment. Deployments start from
the main-branch workflow after merge (or an explicit main-branch deployment
dispatch), retaining the existing environment approval protections. Do not
approve superseded pre-merge apply jobs from older workflow runs.

1. Add delegated Graph `User.Read` to the Entra app registration and arrange
   consent under tenant policy. This repository does not manage Entra.
2. Verify the build checks for the image currently published as `ui-build-latest`.
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
restores its configured release. To disable group checks, disable the account setting and
apply the reviewed listener and UI task-definition changes together; this
restores allow-list-only ALB access. Do not restore an in-app task behind an
authenticating ALB: production revision 15 has that mismatch and can restore
the sign-in loop rather than working access.

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
