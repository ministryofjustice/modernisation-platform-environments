data "aws_subnets" "shared_protected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-protected*"
  }
}

data "aws_subnet" "shared_protected" {
  for_each = toset(data.aws_subnets.shared_protected.ids)
  id       = each.value
}

module "security_group_writer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name            = local.pattern_name
  use_name_prefix = false
  description     = "Outbound SFTP delivery and HTTPS to shared protected subnets; no inbound access"
  vpc_id          = data.aws_vpc.shared.id

  ingress_rules = {}
  egress_rules  = local.writer_egress_rules

  tags = merge(local.tags, { Name = local.pattern_name })
}