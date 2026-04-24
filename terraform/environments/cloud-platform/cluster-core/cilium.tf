module "cilium" {
  count  = contains(["development_cluster"], local.cluster_environment) ? 1 : 0
  source = "github.com/ministryofjustice/container-platform-terraform-cilium?ref=cp3_build" # use the latest release
}
