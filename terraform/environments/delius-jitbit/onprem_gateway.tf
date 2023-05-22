resource "aws_instance" "onprem_gateway" {
  ami           = "ami-070921018feda40c6"
  instance_type = "t3.medium"
#  iam_instance_profile = aws_iam_instance_profile.onprem_gateway.name  
  kms_key_id            = data.aws_kms_key.ebs_shared.arn
  tags = {
    Name = "test"
  }
}

module "onprem_gateway" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "onprem_gateway"

  ami_name                      = "374269020027/mp_WindowsServer2022_2023-04-01T00-00-17.453Z"
  ami_owner                     = "core-shared-services-production"
  instance                      = "t3.medium"
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