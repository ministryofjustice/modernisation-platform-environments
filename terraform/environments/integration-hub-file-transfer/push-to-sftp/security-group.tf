module "security_group_lambda_file_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name            = local.pattern_name
  use_name_prefix = false
  description     = "Outbound SFTP delivery and HTTPS to shared protected subnets; no inbound access"
  vpc_id          = data.aws_vpc.shared.id

  ingress_rules = {}
  egress_rules  = local.egress_rules

  tags = merge(local.tags, { Name = local.pattern_name })
}