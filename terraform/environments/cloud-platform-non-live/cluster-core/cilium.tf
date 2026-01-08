module "cilium" {
  count = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-cilium?ref=1.1.0" # use the latest release
}