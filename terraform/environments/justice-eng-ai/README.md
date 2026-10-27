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

Enabling it adds delegated Microsoft Graph `User.Read` to the ALB OIDC
scopes and sets `MPAPB_ALB_GROUP_AUTHORIZATION_ENABLED=true` on the builder
task definition. The application binds the forwarded access token to the
ALB-signed subject through Microsoft UserInfo, then checks the configured
admin/reviewer group IDs using Graph. The same group intentionally grants
both roles. No tenant-wide Graph application permissions are required.

Rollout order:

1. Add delegated Graph `User.Read` to the Entra app registration and arrange
   consent under tenant policy. This repository does not manage Entra.
2. Build the companion application image with the feature disabled.
3. Review the test and production web-ui Terraform plans. In each, expect the HTTPS listener to add
   `https://graph.microsoft.com/User.Read` and the task-definition flag to
   change from false to true. Development authorisation settings must remain
   unchanged.
4. For each target environment, record the service's current task-definition
   revision for rollback. Apply that environment's infrastructure through the
   approved workflow, then explicitly deploy the compatible application
   image using its new task definition. The verified application
   image tag is `ui-build-5a37ac2`; retain the new task definition's settings
   when pinning the image rather than using the mutable `ui-build-latest` tag.
   The ECS service ignores
   `task_definition`, so Terraform registration is not a service rollout.
   Cloning an old service revision for image deployment can omit the flag.
   The application CI currently does not deploy to test automatically.
5. Start a fresh ALB login with consent to the new scope. Existing ALB
   sessions may continue using tokens without `User.Read`. If necessary,
   remove only that environment's site-specific `AWSELBAuthSessionCookie*` cookies and reload;
   closing and reopening the browser does not reliably clear them.
6. Verify `/auth/user` includes the configured group, `/whoami` returns
   reviewer status, and review read/write access works for team members.
   Verify non-members are denied, Graph errors fail closed, and membership
   removal is reflected after Graph propagation and the 60-second cache.
7. Prefer completing test acceptance before deploying production. Repeat the
   plan, apply, ECS rollout and acceptance checks for production; do not assume
   test results validate production.

Graph availability is required for authenticated dynamic pages while
enabled. Health checks, assets and logout bypass membership lookup.
UserInfo/token identity mismatch gives 401; Graph service or permission
errors give 503. No tokens should be copied to logs, tickets or chat.
For an immediate application rollback, switch the affected service back to
its recorded previous task-definition revision. Remove/disable that account's
setting and apply Terraform to restore its previous listener scope, then
deploy a compatible task definition with the flag false. This restores
allow-list-only ALB access.

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
