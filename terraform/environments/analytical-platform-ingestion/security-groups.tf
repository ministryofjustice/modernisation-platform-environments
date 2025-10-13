locals {
  transfer_server_cidr_blocks_distinct = setunion(
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users : v.cidr_blocks]),
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users_with_egress : v.cidr_blocks])
  )
}

resource "aws_security_group" "connected_vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5

  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.connected_vpc.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "isolated_vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5

  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.isolated_vpc.vpc_id
  tags        = local.tags
}

module "transfer_server_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-transfer-server"
  description = "Security Group for Transfer Server"

  vpc_id = module.isolated_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 2222
      to_port     = 2222
      protocol    = "tcp"
      description = ""
      cidr_blocks = join(",", [for s in local.transfer_server_cidr_blocks_distinct : s])
    }
  ]

  tags = local.tags
}

#tfsec:ignore:avd-aws-0104 - The security group is attached to the resource
module "definition_upload_lambda_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-definition-upload-lambda"
  description = "Security Group for Definition Upload Lambda"

  vpc_id = module.isolated_vpc.vpc_id

  egress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules           = ["all-all"]
  egress_prefix_list_ids = [data.aws_prefix_list.s3.id]

  tags = local.tags
}

module "transfer_lambda_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-transfer-lambda"
  description = "Security Group for Transfer Lambda"

  vpc_id = module.isolated_vpc.vpc_id

  egress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules           = ["all-all"]
  egress_prefix_list_ids = [data.aws_prefix_list.s3.id]

  tags = local.tags
}

module "scan_lambda_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-scan-lambda"
  description = "Security Group for Scan Lambda"

  vpc_id = module.isolated_vpc.vpc_id

  egress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules           = ["all-all"]
  egress_prefix_list_ids = [data.aws_prefix_list.s3.id]

  tags = local.tags
}

module "datasync_activation_nlb_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-datasync-activation-nlb"
  description = "Security Group for DataSync Activation NLB"

  vpc_id = module.connected_vpc.vpc_id

  egress_cidr_blocks = ["${local.environment_configuration.datasync_instance_private_ip}/32"]
  egress_rules       = ["http-80-tcp"]

  ingress_cidr_blocks = ["${data.external.external_ip.result["ip"]}/32"]
  ingress_rules       = ["http-80-tcp"]

  tags = local.tags
}

module "datasync_vpc_endpoint_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-datasync-vpc-endpoint"
  description = "Security Group for DataSync VPC Endpoint"

  vpc_id = module.connected_vpc.vpc_id

  egress_cidr_blocks = [module.connected_vpc.vpc_cidr_block]
  egress_rules       = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 1024
      to_port     = 1064
      protocol    = "tcp"
      description = "DataSync Control Plane"
      cidr_blocks = module.connected_vpc.vpc_cidr_block
    }
  ]

  tags = local.tags
}

module "datasync_task_eni_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-datasync-task-eni"
  description = "Security Group for DataSync Task ENIs"

  vpc_id = module.connected_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "DataSync Data Plane"
      cidr_blocks = module.connected_vpc.vpc_cidr_block
    }
  ]

  tags = local.tags
}

module "datasync_instance_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.application_name}-${local.environment}-datasync-instance"
  description = "Security Group for DataSync Instance"

  vpc_id = module.connected_vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      description = "SMB"
      cidr_blocks = "10.0.0.0/8"
    }
  ]

  egress_with_source_security_group_id = [
    {
      from_port                = 1024
      to_port                  = 1064
      protocol                 = "tcp"
      description              = "DataSync Control Plane"
      source_security_group_id = module.datasync_vpc_endpoint_security_group.security_group_id
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "DataSync Data Plane"
      source_security_group_id = module.datasync_task_eni_security_group.security_group_id
    }
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.datasync_activation_nlb_security_group.security_group_id
    }
  ]

  tags = local.tags
}

moved {
  from = module.datasync_security_group
  to   = module.datasync_instance_security_group
}
