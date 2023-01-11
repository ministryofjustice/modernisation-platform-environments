### not done yet

module "ec2_autoscaling_group_webserver" {
  source = "../modules/ec2_autoscaling_group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.webserver_autoscaling_groups, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_weblogic.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.ec2_weblogic.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = "weblogic/"
  ssm_parameters                = {}
  autoscaling_group             = merge(local.ec2_weblogic.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules = coalesce(lookup(each.value, "autoscaling_schedules", null), {
    # if sizes not set, use the values defined in autoscaling_group
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = lookup(each.value, "offpeak_desired_capacity", 0)
      recurrence       = "0 19 * * Mon-Fri"
    }
  })


  iam_resource_names_prefix = "ec2-weblogic-asg"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit      = local.vpc_name
  application_name   = local.application_name
  environment        = local.environment
  region             = local.region
  availability_zone  = local.availability_zone
  subnet_set         = local.subnet_set
  subnet_name        = "private"
  tags               = merge(local.tags, local.ec2_weblogic.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids

  ansible_repo         = "modernisation-platform-configuration-management"
  ansible_repo_basedir = "ansible"
  branch               = try(each.value.branch, "main")
}