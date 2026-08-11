module "starter_pack" {
  count            = 7
  source           = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=8f889396eff1451a6651edfc1ea72fbc800701a7" #1.3.0
  enable_httproute = true
  hostnames        = ["starter-pack-${count.index+1}.${local.cluster_domain}"]
  namespace        = "starter-pack-${count.index+1}"
  image_repository = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag        = "1.3.0"
}