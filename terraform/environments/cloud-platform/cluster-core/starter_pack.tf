module "starter_pack" {
  count                 = var.enable_starter_pack && local.cluster_environment == "development_cluster" ? 1 : 0
  source                = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=1.3.0"
  enable_httproute      = true
  hostnames             = ["starter-pack.${local.cluster_domain}"]
  image_repository      = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag             = "1.3.0"

  depends_on = [
    module.envoy_gateway
  ]
}