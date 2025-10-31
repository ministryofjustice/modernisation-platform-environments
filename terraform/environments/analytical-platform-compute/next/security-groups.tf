module "rds_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name            = "${local.component_name}-rds"
  use_name_prefix = true

  vpc_id = data.aws_vpc.main.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = join(",", [for s in data.aws_subnet.private : s.cidr_block])
    },
  ]

  tags = local.tags
}
