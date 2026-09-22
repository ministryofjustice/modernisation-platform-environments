locals {
  ec2_autoscaling_groups = {
    for name, instance in local.ec2_instances : name => {
      config = {
        ami_name                      = instance.config.ami_name
        availability_zone             = instance.config.availability_zone
        subnet_name                   = instance.config.subnet_name
        ebs_volumes_copy_all_from_ami = instance.config.ebs_volumes_copy_all_from_ami
        iam_resource_names_prefix     = "ec2-asg-london-unpaid-work"
        instance_profile_policies     = instance.config.instance_profile_policies
        user_data_raw                 = instance.config.user_data_raw
      }

      instance             = instance.instance
      ebs_volumes          = instance.ebs_volumes
      tags                 = instance.tags

      autoscaling_group = {
        desired_capacity = 1
        min_size         = 1
        max_size         = 1
      }
    }
  }
}