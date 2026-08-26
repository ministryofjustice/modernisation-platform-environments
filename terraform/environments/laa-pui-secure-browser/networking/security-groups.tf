module "vpc_endpoints_security_group" {
  count = local.environment == "production" ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${module.vpc[0].name}-vpc-endpoints"
  description = "VPC endpoints security group"

  vpc_id = module.vpc[0].vpc_id

  ingress_cidr_blocks = [module.vpc[0].vpc_cidr_block]
  ingress_rules       = ["https-443-tcp"]

  tags = local.tags
}
