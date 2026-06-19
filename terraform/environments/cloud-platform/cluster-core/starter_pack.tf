locals {
  starter_pack_namespace          = "starter-pack"
  starter_pack_httproute_hostname = format("%s.%s.%s", local.starter_pack_namespace, local.cluster_name, local.cluster_base_domain)
}

module "starter_pack" {
  # count             = var.enable_starter_pack && local.cluster_environment == "development_cluster" ? 1 : 0

  count = 3
  source            = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=1.2.1"
  namespace         = "${local.starter_pack_namespace}-${count.index}"
  gateway_name      = "eg"
  gateway_namespace = "envoy-gateway-system"
  hostnames         = ["test${count.index}-${local.starter_pack_httproute_hostname}"]
  enable_httproute  = true # HTTPRoute can't be created until gateway API CRDs are installed 
  image_repository  = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag         = "1.2.1"
}
