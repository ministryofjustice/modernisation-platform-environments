module "quicksight_shared_vpc_security_group" {

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa" # v5.3.1


  name = "quicksight-shared-vpc"

  vpc_id = data.aws_vpc.shared.id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = local.tags
}
