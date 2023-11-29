module "datahub_rds_security_group" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name = "datahub-rds"

  vpc_id = data.aws_vpc.dedicated.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = join(",", [for subnet in data.aws_subnet.private : subnet.cidr_block])
    },
  ]

  tags = local.tags
}