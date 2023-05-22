module "onprem_gateway" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "onprem_gateway"

  ami_name                      = "374269020027/mp_WindowsServer2022_2023-04-01T00-00-17.453Z"
  ami_owner                     = "core-shared-services-production"
  instance                      = {}
  ebs_volumes_copy_all_from_ami = true
  ebs_kms_key_id                = data.aws_kms_key.ebs_shared.arn
  ebs_volume_config             = {}
  ebs_volumes                   = {}
  ssm_parameters_prefix         = null
  ssm_parameters                = null
  route53_records               = {}

  iam_resource_names_prefix = ""
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit            = var.networking[0].business-unit
  application_name         = local.application_name
  environment              = local.environment
  region                   = local.region
  availability_zone        = local.availability_zone_1
  subnet_id                = module.environment.subnet["private"][local.availability_zone_1].id
  tags                     = {}
  account_ids_lookup       = local.environment_management.account_ids
  cloudwatch_metric_alarms = {}
}

locals {
  # ec2_common_managed_policies = [
  #   aws_iam_policy.ec2_common_policy.arn
  # ]
  instance = {
    disable_api_termination      = false
    instance_type                = "t3.medium"
    key_name                     = try(aws_key_pair.ec2-user.key_name)
    monitoring                   = false
    metadata_options_http_tokens = "required"
    vpc_security_group_ids       = try([aws_security_group.example_ec2_sg.id])
  }
}

# create single managed policy
# resource "aws_iam_policy" "ec2_common_policy" {
#   name        = "ec2-common-policy"
#   path        = "/"
#   description = "Common policy for all ec2 instances"
#   policy      = data.aws_iam_policy_document.ec2_common_combined.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "ec2-common-policy"
#     },
#   )
# }

# # combine ec2-common policy documents
# data "aws_iam_policy_document" "ec2_common_combined" {
#   source_policy_documents = [
#     data.aws_iam_policy_document.ec2_policy.json,
#   ]
# }

# # custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
# data "aws_iam_policy_document" "ec2_policy" {
#   statement {
#     sid    = "CustomEc2Policy"
#     effect = "Allow"
#     actions = [
#       "ec2:*"
#     ]
#     resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
#   }
# }