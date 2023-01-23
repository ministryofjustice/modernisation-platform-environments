locals {
  default_tags = {
    server-name = var.name
  }
  ssm_parameters_prefix_tag = var.ssm_parameters_prefix == "" ? {} : {
    ssm-parameters-prefix = var.ssm_parameters_prefix
  }
  tags = merge(local.default_tags, local.ssm_parameters_prefix_tag, var.tags)

  ami_block_device_mappings = {
    for bdm in data.aws_ami.this.block_device_mappings : bdm.device_name => bdm
  }

  ebs_volumes_from_ami = {
    for key, value in local.ami_block_device_mappings : key => {
      snapshot_id  = try(value.ebs.snapshot_id, null)
      iops         = try(value.ebs.iops, null)
      throughput   = try(value.ebs.throughput, null)
      size         = try(value.ebs.volume_size, null)
      type         = try(value.ebs.volume_type, null)
      no_device    = value.no_device
      virtual_name = value.virtual_name
    }
  }

  # See README, allow volumes to be grouped by labels, e.g. "data", "app" and so on.
  ebs_volume_labels = distinct(flatten([for key, value in var.ebs_volumes : lookup(value, "label", [])]))
  ebs_volume_count = {
    for label in local.ebs_volume_labels :
    label => length([for key, value in var.ebs_volumes : key if try(value.label == label, false)])
  }
  ebs_volumes_swap_size = data.aws_ec2_instance_type.this.memory_size >= 16384 ? 16 : (data.aws_ec2_instance_type.this.memory_size / 1024)
  ebs_volumes_from_config = {
    for key, value in var.ebs_volumes :
    key => {
      iops       = try(var.ebs_volume_config[value.label].iops, null)
      throughput = try(var.ebs_volume_config[value.label].throughput, null)
      type       = try(var.ebs_volume_config[value.label].type, null)
      size = try(
        floor(var.ebs_volume_config[value.label].total_size / local.ebs_volume_count[value.label]),
        try(value.label == "swap", false) ? local.ebs_volumes_swap_size : null
      )
    }
  }

  # merge AMI and var.ebs_volume values, e.g. allow AMI settings to be overridden
  ebs_volume_names = var.ebs_volumes_copy_all_from_ami ? keys(merge(var.ebs_volumes, local.ami_block_device_mappings)) : keys(var.ebs_volumes)

  ebs_volumes = {
    for key in local.ebs_volume_names :
    key => merge(
      try(local.ebs_volumes_from_ami[key], {}),
      try(local.ebs_volumes_from_config[key], {}),
      try(var.ebs_volumes[key], {})
    )
  }

  user_data_args_ssm_params = {
    for key, value in var.ssm_parameters != null ? var.ssm_parameters : {} :
    "ssm_parameter_${key}" => aws_ssm_parameter.this[key].name
  }

  user_data_args_common = {
    branch               = var.branch == "" ? "main" : var.branch
    ansible_repo         = var.ansible_repo == null ? "" : var.ansible_repo
    ansible_repo_basedir = var.ansible_repo_basedir == null ? "" : var.ansible_repo_basedir
    ansible_args         = "--tags ec2provision"
  }

  user_data_args = merge(local.user_data_args_common, local.user_data_args_ssm_params, try(var.user_data_cloud_init.args, {}))

  user_data_raw = var.user_data_raw

  user_data_part_count = [
    try(length(var.user_data_cloud_init.scripts), 0),
    try(length(var.user_data_cloud_init.write_files), 0)
  ]

  lb_target_group_arns        = [for key, value in aws_lb_target_group.this : value.arn]
  merged_lb_target_group_arns = concat(coalesce(var.autoscaling_group.target_group_arns, []), local.lb_target_group_arns)
}
