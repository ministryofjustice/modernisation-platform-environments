locals {
  starter_pack_namespace          = "starter-pack"
  starter_pack_httproute_hostname = format("%s.%s.%s", local.starter_pack_namespace, local.cluster_name, local.cluster_base_domain)
}

module "starter_pack" {
  source = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=1.2.1"

  count             = 3
  namespace         = "${local.starter_pack_namespace}-${count.index}"
  hostnames         = ["test${count.index}-${local.starter_pack_httproute_hostname}"]
  gateway_name      = "eg"
  gateway_namespace = "envoy-gateway-system"
  enable_httproute  = true # HTTPRoute can't be created until gateway API CRDs are installed

  image_repository = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag        = "1.2.1"

  depends_on = [module.gateway_api, module.cert_manager]
}
