module "mwaa_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name = "mwaa"

  vpc_id = data.aws_vpc.apc_vpc.id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_cidr_blocks = [data.aws_vpc.apc_vpc.cidr_block]
  ingress_rules       = ["all-all"]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  tags = local.tags
}
