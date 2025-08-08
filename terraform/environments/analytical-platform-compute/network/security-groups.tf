module "vpc_endpoints_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${module.vpc.name}-vpc-endpoints"
  description = "VPC endpoints security group"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_rules       = ["https-443-tcp"]

  tags = local.tags
}
