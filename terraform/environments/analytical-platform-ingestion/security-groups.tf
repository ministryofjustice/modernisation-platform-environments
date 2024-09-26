resource "aws_security_group" "vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5

  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.isolated_vpc.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "transfer_server" {
  description = "Security Group for Transfer Server"
  name        = "transfer-server"
  vpc_id      = module.isolated_vpc.vpc_id
}

#tfsec:ignore:avd-aws-0104 - The security group is attached to the resource
module "definition_upload_lambda_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

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
  version = "5.2.0"

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
  version = "5.2.0"

  name        = "${local.application_name}-${local.environment}-scan-lambda"
  description = "Security Group for Scan Lambda"

  vpc_id = module.isolated_vpc.vpc_id

  egress_cidr_blocks     = ["0.0.0.0/0"]
  egress_rules           = ["all-all"]
  egress_prefix_list_ids = [data.aws_prefix_list.s3.id]

  tags = local.tags
}
