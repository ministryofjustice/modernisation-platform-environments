locals {
  #-----------------------------------------------------------------------------
  # AMG host designation
  #
  # The centralised Amazon Managed Grafana workspace is deployed only in the
  # workspaces listed here (ADR-005, updated 2026-09-07):
  #   - cloud-platform-live: the production central AMG serving all BUs and
  #     both live and non-live environments (single workspace).
  #   - cloud-platform-development: a test AMG in the development account so
  #     ephemeral clusters' dashboards and data sources can be validated.
  #
  # Any other workspace (BU spokes, preproduction, nonlive) plans an empty
  # state for this component. Deployment intent is declared here, not via
  # -var flags.
  #-----------------------------------------------------------------------------
  amg_host_workspaces = [
    "cloud-platform-live",
    "cloud-platform-development",
  ]

  enable_amg = contains(local.amg_host_workspaces, terraform.workspace)

  amg_workspace_name = "${terraform.workspace}-observability"
}
