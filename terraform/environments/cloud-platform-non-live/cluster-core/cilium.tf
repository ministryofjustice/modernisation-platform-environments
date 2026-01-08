module "cilium" {
  count = local.environment_configuration.enable_culium ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-cilium?ref=1.1.0" # use the latest release
}