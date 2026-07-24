variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}

# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
data "aws_codestarconnections_connection" "github" {
  name = "github-ministryofjustice"
}

locals {
  argocd_codeconnection_arn = data.aws_codestarconnections_connection.github.arn
}
