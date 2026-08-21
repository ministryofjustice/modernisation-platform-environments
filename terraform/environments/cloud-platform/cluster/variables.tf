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
#------------------------------------------------------------------------------
variable "enable_argocd" {
  type        = bool
  default     = false
  description = "Enable the EKS Capability for Argo CD on this cluster (hub cluster role)."
}

variable "argocd_idc_instance_arn" {
  type = string
  # Org-wide IAM Identity Center instance — the same ARN across all MoJ accounts.
  default     = "arn:aws:sso:::instance/ssoins-7535d9af4f41fb26"
  description = "ARN of the AWS IAM Identity Center instance for Argo CD authentication. Required when enable_argocd is true. Defaults to the org-wide IDC instance."
}

variable "argocd_idc_region" {
  type        = string
  default     = "eu-west-2"
  description = "Region of the IAM Identity Center instance."
}

variable "argocd_rbac_role_mappings" {
  type = map(list(object({
    id   = string
    type = string
  })))
  default     = {}
  description = <<-EOT
    Additional RBAC role mappings for ArgoCD beyond the admin group.
    Keys: ADMIN, EDITOR, VIEWER. Values: list of IDC identity objects.
    Used to grant BU teams access to the ArgoCD UI.
    Example: { VIEWER = [{ id = "hmpps-sre-group-id", type = "SSO_GROUP" }] }
  EOT
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
