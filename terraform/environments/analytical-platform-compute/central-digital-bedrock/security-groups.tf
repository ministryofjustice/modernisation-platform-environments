module "rds_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name = "rds"

  vpc_id = data.aws_vpc.shared.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from private subnets"
      cidr_blocks = join(",", [
        data.aws_subnet.private_subnets_a.cidr_block,
        data.aws_subnet.private_subnets_b.cidr_block,
        data.aws_subnet.private_subnets_c.cidr_block
      ])
    },
  ]

  tags = local.tags
}