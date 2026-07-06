module "starter_pack" {
  count                 = var.enable_starter_pack && local.cluster_environment == "development_cluster" ? 1 : 0
  source                = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=3eef061a86773a417f06565d73e64ded155d645f"

  depends_on = [ module.gateway_api ]

  listenerset_name      = "default-listenerset"
  listenerset_namespace = "envoy-gateway-system"
  enable_httproute      = true # HTTPRoute can't be created until gateway API CRDs are installed
  hostnames             = ["starter-pack-${count.index}.apps.${local.cluster_name}.development.container-platform.service.justice.gov.uk"]
  image_repository      = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag             = "1.2.1"
}
