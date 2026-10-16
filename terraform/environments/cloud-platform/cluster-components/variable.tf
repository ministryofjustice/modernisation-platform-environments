variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}

#------------------------------------------------------------------------------
# Observability PoC feature flags
#
# All default to false. Enable explicitly via workflow -var flags, e.g.:
#   "-var=enable_amp_adot=true -var=enable_cloudwatch_observability=true"
#
# This ensures no observability resources are deployed unless a user explicitly
# opts in, regardless of environment.
#------------------------------------------------------------------------------

variable "enable_amp_adot" {
  type        = bool
  default     = false
  description = "Deploy AMP workspace + ADOT collector pipeline (Option A). Must be explicitly enabled."
}

variable "enable_cloudwatch_observability" {
  type        = bool
  default     = false
  description = "Deploy OTel Container Insights add-on (Option D). Must be explicitly enabled."
}

variable "enable_amp_rules_logging" {
  type    = bool
  default = false
  # When true, attaches an inline AMP rules/alerting logging_configuration to the
  # workspace (and creates its CloudWatch log group). Only logs anything when the
  # workspace has recording/alerting rules or an alertmanager definition, so it is
  # off by default and intended for production once rule groups exist.
  #
  # Known limitation (ministryofjustice/cloud-platform#8611): the hashicorp/aws
  # provider (v6.69.1) has no standalone rules-logging resource, so Terraform
  # cannot delete the logging configuration before the workspace on destroy.
  # Destroying a workspace with this flag ON fails with a misleading
  # 403 AccessDenied on DeleteWorkspace. Manual pre-destroy workaround:
  #   aws amp delete-logging-configuration --workspace-id <id>
  #   aws amp delete-workspace --workspace-id <id>
  # Leave OFF for ephemeral/PoC clusters so they destroy cleanly.
  description = "Attach an inline AMP rules/alerting logging configuration to the workspace. Must be explicitly enabled. See cloud-platform#8611: enabling blocks clean destroy (no standalone rules-logging resource in the provider)."
}
