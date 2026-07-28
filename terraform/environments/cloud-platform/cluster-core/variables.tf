variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}

# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
#
# Only looked up on hub clusters (argocd-role=hub tag). BU spoke accounts
# (container-platform-* workspaces) do not have a CodeConnection and would
# fail at plan time without this guard.
data "aws_codestarconnections_connection" "github" {
  count = lookup(data.aws_eks_cluster.cluster.tags, "argocd-role", "") == "hub" ? 1 : 0
  name  = "github-ministryofjustice"
}

locals {
  argocd_codeconnection_arn = length(data.aws_codestarconnections_connection.github) > 0 ? data.aws_codestarconnections_connection.github[0].arn : ""
}
