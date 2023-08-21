# Ec2
module "ec2_kinesis_agent" {
  source                      = "./modules/ec2"
  name                        = "${local.project}-ec2-kinesis-agent-${local.env}"
  description                 = "EC2 instance for kinesis agent"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  # s3_policy_arn               = aws_iam_policy.read_s3_read_access_policy.arn # TBC
  region  = local.account_region
  account = local.account_id
  env     = local.env


  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-ec2-kinesis-agent-${local.env}"
      Resource_Type = "EC2 Instance"
    }
  )
}

module "domain_builder_cli_agent" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-tools-ssm-agent-${local.env}"
  description                 = "DPR SPecific Tools, SSM Agent"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.apigateway_get_policy}", ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "domain-builder"

  env_vars = {
      DOMAIN_API_KEY = tostring(try(module.domain_builder_api_key[0].secret, null))
      REST_API_EXEC_ARN = tostring(try(module.domain_builder_api_gateway[0].rest_api_execution_arn, null))
      REST_API_ID = tostring(try(module.domain_builder_api_gateway[0].rest_api_id, null))
      ENV = local.env
  }

  tags = merge(
    local.all_tags,
    {
      Name            = "${local.project}-tools-ssm-agent-${local.env}"
      Resource_Type   = "EC2 Instance"
      Resource_Group  = "dpr-tools"
      Name            = "${local.project}-tools-ssm-agent-${local.env}"
    }
  )
}