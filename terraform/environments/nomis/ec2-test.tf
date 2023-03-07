#------------------------------------------------------------------------------
# EC2 Instances following naming convention
#------------------------------------------------------------------------------

locals {

  ec2_test = {

    # server-type and nomis-environment auto set by module
    tags = {
      component = "test"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = false
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.private.id]
    }

    user_data_cloud_init = {
      args = {
        lifecycle_hook_name  = "ready-hook"
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision"
      }
      scripts = [
        "install-ssm-agent.sh.tftpl",
        "ansible-ec2provision.sh.tftpl",
        "post-ec2provision.sh.tftpl"
      ]
    }

    route53_records = {
      create_internal_record = true
      create_external_record = false
    }

    # user can manually increase the desired capacity to 1 via CLI/console
    # to create an instance
    autoscaling_group = {
      desired_capacity = 0
      max_size         = 2
      min_size         = 0
    }
  }
}

module "ec2_test_instance" {
  #checkov:skip=CKV_AWS_126:This is a test instance
  source = "../../modules/ec2_instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_test_instances, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.ec2_test.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  route53_records               = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {}))

  iam_resource_names_prefix = "ec2-test-instance"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit            = local.business_unit
  application_name         = local.application_name
  environment              = local.environment
  region                   = local.region
  availability_zone        = local.availability_zone_1
  subnet_id                = module.environment.subnet["private"][local.availability_zone_1].id
  tags                     = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup       = local.environment_management.account_ids
  cloudwatch_metric_alarms = {}
}

module "ec2_test_autoscaling_group" {
  source = "../../modules/ec2_autoscaling_group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_test_autoscaling_groups, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.ec2_test.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  autoscaling_group             = merge(local.ec2_test.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules         = lookup(each.value, "autoscaling_schedules", local.autoscaling_schedules_default)

  iam_resource_names_prefix = "ec2-test-asg"
  instance_profile_policies = local.ec2_common_managed_policies
  application_name          = local.application_name
  region                    = local.region
  subnet_ids                = module.environment.subnets["private"].ids
  tags                      = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup        = local.environment_management.account_ids
  cloudwatch_metric_alarms  = {}
}
