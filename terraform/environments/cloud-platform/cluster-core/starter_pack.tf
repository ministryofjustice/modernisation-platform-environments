module "starter_pack" {
  count             = var.enable_starter_pack && local.cluster_environment == "development_cluster" ? 1 : 0
  source            = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=remove-leftover-latest-tag"
  gateway_name      = "eg"
  gateway_namespace = "default"
  enable_httproute  = false # HTTPRoute can't be created until gateway API CRDs are installed 
  image_repository  = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag         = "1.0.0"
}
