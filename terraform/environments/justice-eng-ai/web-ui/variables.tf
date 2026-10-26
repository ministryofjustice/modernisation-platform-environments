variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
  default     = {}
}

variable "application_name" {
  type        = string
  description = "Name of application"
  default     = ""
}

variable "bedrock_model_id" {
  type        = string
  description = <<-EOT
    Amazon Bedrock model ID used by the builder UI. In eu-* regions this
    MUST use the ``eu.`` cross-region inference profile prefix -- the
    plain ``anthropic.…`` id will fail with a ValidationException.
    Kept in sync with app/policy/schema.py MODEL_DEFAULT and every other
    reference in this repo.
  EOT
  default     = "eu.anthropic.claude-sonnet-5-5"
}

variable "enable_oidc_auth" {
  type        = bool
  description = "Whether to provision Entra ID OIDC secrets (and, in a follow-up, wire the ALB `authenticate-oidc` listener action). Secrets are created empty by Terraform and populated out-of-band; see oidc.tf."
  default     = true
}

variable "oidc_configured" {
  type        = bool
  description = <<-EOT
    Whether the three Entra OIDC secrets in Secrets Manager already hold
    populated values. Setting this to true causes the ALB listener to be
    wired with the ``authenticate-oidc`` action; leave false during the
    first apply (secrets are created empty) and flip to true only after
    populating the values via ``aws secretsmanager put-secret-value``.
  EOT
  default     = true
}

variable "enable_in_app_oidc" {
  type        = bool
  description = <<-EOT
    Whether the UI container performs its own Entra OIDC handshake
    instead of relying on the ALB ``authenticate-oidc`` listener action.

    NOTE: this is now only the FALLBACK. An account's
    ``builder_auth_mode`` in application_variables.json ("in-app" or
    "alb") takes precedence; this variable applies only to accounts
    without that key (true -> "in-app", false -> "alb"). See oidc.tf.

    When in-app is selected:

      * the ALB listener drops ``authenticate-oidc`` and forwards plainly
        to the container (the app owns login / session / logout);
      * ``MPAPB_ENTRA_ENABLED=true`` is set on the ECS task, plus the
        tenant / client-id / client-secret secrets are injected under the
        ``MPAPB_ENTRA_*`` env-var names;
      * ``MPAPB_TRUST_ALB_OIDC`` is forced to false so a spoofed header
        can't grant identity when the ALB is no longer setting one.

    Requires ``enable_oidc_auth = true`` and ``oidc_configured = true`` so
    the underlying secrets exist and hold populated values.

    Default true now that both accounts' secrets are populated and their
    redirect URIs are registered in the shared Entra app registration.
  EOT
  default     = true
}

variable "entra_admin_group_id" {
  type        = string
  description = <<-EOT
    Optional Entra group object ID (GUID) whose members become admins
    when in-app OIDC is enabled. Presence in the id_token ``groups``
    claim -> ``roles.is_admin`` returns true. Group object IDs are not
    secret (they identify a group, not a user), so this ships as a plain
    tfvar rather than in Secrets Manager. Leave empty to disable
    admin-role wiring.
  EOT
  default     = "d0c842bc-1581-47b6-af5c-409db76fbbf2"
  validation {
    condition     = var.entra_admin_group_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.entra_admin_group_id))
    error_message = "entra_admin_group_id must be empty or a GUID."
  }
}

variable "entra_reviewer_group_id" {
  type        = string
  description = <<-EOT
    Optional Entra group object ID (GUID) whose members can access the
    reviewer dashboard when in-app OIDC is enabled. Presence in the
    id_token ``groups`` claim -> ``roles.is_reviewer_via_group`` returns
    true. See ``entra_admin_group_id`` for why this isn't a secret. Leave
    empty to fall back on ``MPAPB_REVIEWER_USER_IDS`` for break-glass
    reviewer authorisation.
  EOT
  default     = "d0c842bc-1581-47b6-af5c-409db76fbbf2"
  validation {
    condition     = var.entra_reviewer_group_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.entra_reviewer_group_id))
    error_message = "entra_reviewer_group_id must be empty or a GUID."
  }
}

variable "builder_hostname" {
  type        = string
  description = "Hostname for the AI prototype builder UI. Leave empty to use the environment-scoped default in locals.tf (production gets the bare hostname, every other workspace gets a '-<environment>' suffix so dev and prod don't collide)."
  default     = ""
}

variable "container_image_tag" {
  type        = string
  description = "Container image tag to run from ECR. CI/CD now publishes the newest UI image under the moving tag ui-build-latest, so this defaults to that to stop Terraform registering task-definition revisions that point at an old pinned build. The service ignores task_definition changes (see aws_ecs_service.app), so a new deployment is still needed to pick up a fresh image."
  default     = "ui-build-latest"
}

variable "forge_container_image_tag" {
  type        = string
  description = "Image tag to run for the Forge Journey Lab container, pulled from the same shared-services ECR repository as the UI image (the moving forge-build-latest tag, not the UI's ui-build-latest tag). Same ignore_changes caveat as container_image_tag applies once CI/CD takes over."
  default     = "forge-build-latest"
}

variable "app_container_port" {
  type        = number
  description = "Port exposed by the UI container."
  default     = 8000
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the ECS task."
  default     = 512
}

variable "task_memory" {
  type        = number
  description = "Memory in MiB for the ECS task."
  default     = 1024
}

variable "app_desired_count" {
  type        = number
  description = "Desired number of UI tasks. Set to 0 to stop the service without destroying resources."
  default     = 1
}

# ---------- GitHub App -- used by the UI to fire repository_dispatch ----------
#
# App id + owner + repo + event type + workflow file name are non-sensitive
# and go into the task-def as plain environment variables. The installation
# id and the private key are pulled from Secrets Manager (see secrets.tf).

variable "github_app_id" {
  type        = string
  description = "Numeric App id for the Modernisation Platform GitHub App. Public value; matches scorecards.yml."
  default     = "2013696"
}

variable "github_owner" {
  type        = string
  description = "GitHub org / owner of the repo that receives repository_dispatch."
  default     = "ministryofjustice"
}

variable "github_repo" {
  type        = string
  description = "Repository that receives repository_dispatch (i.e. this repo)."
  default     = "modernisation-platform-ai-prototype-builder"
}

variable "github_event_type" {
  type        = string
  description = "repository_dispatch event_type consumed by intake.yml."
  default     = "prototype-intake"
}

variable "github_intake_workflow_file" {
  type        = string
  description = "Workflow file the UI polls for live Control-plane status."
  default     = "intake.yml"
}

variable "reviewer_user_ids" {
  type        = string
  description = <<EOT
Comma-separated 12-hex ``user_id`` values (the value
``ui/app/auth.resolve_user`` returns) that get reviewer access without an
Entra reviewer or administrator group claim. This is a break-glass mechanism;
prefer granting access through the relevant Entra group.

Users can find their own id via ``/whoami`` while signed in.
EOT
  default     = ""
}

variable "deployment_email_override" {
  type        = string
  description = <<EOT
Operator override for the ``email_id`` input on the Deployment workflow
dispatch. Empty (default) sends the empty string -- matches the
caller-agnostic behaviour of ``dispatch_deployment_workflow``.

Set (via ``TF_VAR_deployment_email_override`` or terraform.tfvars) while
the intake payload does not yet carry a real requester email and the
Deployment workflow's "build complete" email step needs a known-good
address to exercise. Remove when real per-user email plumbing lands.
EOT
  default     = ""
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = <<EOT
CIDR blocks allowed to hit the builder ALB on 443. The defaults cover the
MoJ GlobalProtect / Prisma Access egress fleet:

  - 4x /32s: MoJ core-network-services NAT gateway EIPs in AWS eu-west-2
    (one per AZ + HA). These are the source IPs the ALB sees when a MoJ
    device on GP reaches an AWS eu-west-2 destination via the tunnel.
  - 1x /26: Palo Alto Networks Prisma Access cloud gateway range that MoJ
    routes GP traffic through when a user's tunnel exits via Palo Alto's
    SASE POPs rather than the MoJ-owned AWS NAT.

Verified against a VPC flow log capture on 2026-07-14 that showed traffic
from a GP-connected MoJ device landing at the ALB with source IP
35.176.93.186 (one of the /32s below).
EOT
  default = [
    "18.169.147.172/32", # MoJ core-network-services NAT (eu-west-2a)
    "35.176.93.186/32",  # MoJ core-network-services NAT (eu-west-2b)
    "18.130.148.126/32", # MoJ core-network-services NAT (eu-west-2c)
    "35.176.148.126/32", # MoJ core-network-services NAT (HA)
    "128.77.75.64/26",   # Palo Alto Networks Prisma Access (MoJ GP cloud gw)
  ]
}

variable "forge_deployment_mode" {
  type        = string
  description = <<-EOT
    How this stack provides Forge Journey Lab to the builder UI's iframe
    (see ui/static/forge.html -- the browser loads MPAPB_FORGE_URL directly,
    Forge is never called server-side by the UI). One of:

      "internal" -- deploy Forge's own ECS service, ECR repo, secrets and
        EFS access point here, fronted by this ALB via a host-based
        listener rule, with its own Route 53 record (current default).

      "external" -- Forge is already deployed elsewhere. Set
        `external_forge_url` to its browser-reachable HTTPS URL; no Forge
        ECS/ALB/DNS resources are created by this stack.

      "disabled" -- no Forge integration at all. `MPAPB_FORGE_URL` is left
        unset and no Forge DNS record is created.
  EOT
  default     = "internal"
  validation {
    condition     = contains(["internal", "external", "disabled"], var.forge_deployment_mode)
    error_message = "forge_deployment_mode must be one of: internal, external, disabled."
  }
}

variable "external_forge_url" {
  type        = string
  description = "Browser-reachable HTTPS URL of an already-deployed Forge Journey Lab instance. Required when forge_deployment_mode = \"external\"; ignored otherwise."
  default     = ""
  validation {
    condition     = var.forge_deployment_mode != "external" || var.external_forge_url != ""
    error_message = "external_forge_url must be set when forge_deployment_mode = \"external\"."
  }
}

variable "forge_package_s3_bucket" {
  type        = string
  description = <<-EOT
    Override for the S3 bucket where Forge Journey Lab writes "Package for
    deployment" artefacts (``s3://<bucket>/<forge_package_s3_prefix><appId>/<buildId>.json``).
    Leave empty (the default) to use the sibling backend-processing root's
    staging bucket instead -- see local.forge_package_s3_bucket in
    locals.tf, which reads that bucket's name via terraform_remote_state.
    That bucket is NOT managed by this root; it's created in
    backend-processing/s3.tf. Set this var only to point Forge at a
    different bucket than that default.
  EOT
  default     = ""
}

variable "forge_package_s3_prefix" {
  type        = string
  description = "Key prefix inside forge_package_s3_bucket under which the artefacts land. Must end in '/' if non-empty."
  default     = "forge-builds/"
}
