variable "created_by" {
  type        = string
  default     = null
  description = "User or system identifier to stamp into the immutable created-by tag (set via TF_VAR_created_by on first apply)."

  validation {
    condition     = var.created_by == null || length(trimspace(var.created_by)) > 0
    error_message = "created_by must not be empty."
  }
}

#------------------------------------------------------------------------------
# Argo CD Hub Cluster Configuration (ADR-002)
#
# Only per-cluster ephemeral toggles remain as variables. Constant configuration
# (IDC instance/region) lives in locals.tf; per-tier RBAC mappings live in the
# environment_configurations map (environment-configuration.tf).
#------------------------------------------------------------------------------
variable "enable_argocd" {
  type        = bool
  default     = false
  description = "Enable the EKS Capability for Argo CD on this cluster (hub cluster role). Set via TF_VAR_enable_argocd=true for ephemeral test hubs; permanent hubs are matched by workspace name in local.argocd_hubs."
}

#------------------------------------------------------------------------------
# Argo CD Spoke Registration (ADR-002 — Spoke-Driven Model)

variable "argocd_hub_capability_role_arn" {
  type        = string
  default     = ""
  description = "Optional override for the hub cluster's ArgoCD Capability IAM role ARN. Leave empty in the normal cases: permanent spokes resolve the ARN by convention from local.argocd_hubs (their tier hub), and ephemeral '-spoke' dev clusters resolve it from their convention-paired '<prefix>-hub' in the same account. Set this only to pair an ephemeral spoke with a hub that does not follow the naming convention."
}

resource "null_resource" "created_by_tag" {
  triggers = {
    # Persist the initial creator value in state; ignore future tf var changes.
    created_by = coalesce(var.created_by, "__unset__")
  }

  lifecycle {
    ignore_changes = [triggers["created_by"]]
  }
}
