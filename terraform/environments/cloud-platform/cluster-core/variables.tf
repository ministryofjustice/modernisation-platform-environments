variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}

variable "argocd_codeconnection_arn" {
  type        = string
  default     = ""
  description = <<-EOT
    AWS CodeConnections ARN used by the EKS-managed Argo CD to reach the GitOps
    repository. When empty, looks up the connection by name
    (github-ministryofjustice) via data source.
    Falls back to direct GitHub URL if neither is available.
  EOT
}

# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
data "aws_codestarconnections_connection" "github" {
  count = var.argocd_codeconnection_arn == "" && local.is_argocd_hub ? 1 : 0
  name  = "github-ministryofjustice"
}

locals {
  # Resolve CodeConnections ARN: explicit variable > data source > empty (direct GitHub)
  resolved_codeconnection_arn = var.argocd_codeconnection_arn != "" ? var.argocd_codeconnection_arn : try(data.aws_codestarconnections_connection.github[0].arn, "")
}
