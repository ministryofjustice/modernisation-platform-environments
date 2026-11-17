module "cloud_platform_live_1_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name = "cloud-platform/live-1"

  secret_string = jsonencode({
    cluster_name           = "live-1"
    cluster_endpoint       = "CHANGEME"
    cluster_ca_certificate = "CHANGEME"
  })

  ignore_secret_changes = true
}
