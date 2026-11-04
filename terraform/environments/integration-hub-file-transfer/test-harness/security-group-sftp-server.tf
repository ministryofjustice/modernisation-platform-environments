data "aws_subnet" "sftp" {
  count = local.create_test_harness ? 1 : 0

  id = local.sftp_subnet_id
}

data "aws_security_group" "sftp_writer" {
  count = local.create_test_harness ? 1 : 0

  name   = local.sftp_writer_security_group_name
  vpc_id = data.aws_vpc.shared.id
}

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
  for_each = local.create_test_harness ? toset(data.aws_subnets.shared_protected.ids) : toset([])

  id = each.value
}

data "aws_ec2_managed_prefix_list" "s3" {
  count = local.create_test_harness ? 1 : 0

  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

module "security_group_sftp_server" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  create = local.create_test_harness

  name            = local.sftp_server_name
  use_name_prefix = false
  description     = "Inbound SFTP from the push-to-sftp writer only; HTTPS to shared endpoints and S3"
  vpc_id          = data.aws_vpc.shared.id

  ingress_rules = local.create_test_harness ? {
    sftp_from_writer = {
      description                  = "SFTP from the push-to-sftp writer"
      referenced_security_group_id = data.aws_security_group.sftp_writer[0].id
      ip_protocol                  = "tcp"
      from_port                    = 22
      to_port                      = 22
    }
  } : {}
  egress_rules = local.sftp_egress_rules

  tags = merge(local.tags, { Name = local.sftp_server_name })
}
