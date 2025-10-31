module "rds_security_group" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name = "dashboard-service"

  vpc_id = data.aws_vpc.apc_vpc.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = join(",", [for s in data.aws_subnet.apc_private : s.cidr_block])
    },
  ]

  tags = local.tags
}
