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

  ami_block_device_mappings_nonroot = {
    for key, value in local.ami_block_device_mappings :
    key => value if key != data.aws_ami.this.root_device_name
  }

  ebs_volumes_from_ami = {
    for key, value in local.ami_block_device_mappings : key => {
      snapshot_id  = lookup(value.ebs, "snapshot_id", null)
      iops         = lookup(value.ebs, "iops", null)
      throughput   = lookup(value.ebs, "throughput", null)
      size         = lookup(value.ebs, "volume_size", null)
      type         = lookup(value.ebs, "volume_type", null)
      no_device    = value.no_device
      virtual_name = value.virtual_name
    }
  }

  # remove nulls so merge() doesn't include them
  ebs_volumes_without_nulls = {
    for key1, value1 in var.ebs_volumes :
    key1 => {
      for key2, value2 in value1 : key2 => value2 if value2 != null
    }
  }

  # See README, allow volumes to be grouped by labels, e.g. "data", "app" and so on.
  ebs_volume_labels = distinct(flatten([for key, value in local.ebs_volumes_without_nulls : lookup(value, "label", [])]))
  ebs_volume_count = {
    for label in local.ebs_volume_labels :
    label => length([for key, value in local.ebs_volumes_without_nulls : key if value.label == label])
  }
  ebs_volumes_from_config = {
    for key, value in local.ebs_volumes_without_nulls :
    key => {
      iops       = var.ebs_volume_config[value.label].iops
      kms_key_id = var.ebs_volume_config[value.label].kms_key_id
      throughput = var.ebs_volume_config[value.label].throughput
      type       = var.ebs_volume_config[value.label].type
      size       = var.ebs_volume_config[value.label].total_size != null ? var.ebs_volume_config[value.label].total_size / local.ebs_volume_count[value.label] : null
    } if contains(keys(var.ebs_volume_config), lookup(value, "label", "-"))
  }

  # Auto calculate swap volume size based on instance memory size
  ebs_volumes_swap_size = data.aws_ec2_instance_type.this.memory_size >= 16384 ? 16 : (data.aws_ec2_instance_type.this.memory_size / 1024)
  ebs_volumes_swap = {
    for key, value in local.ebs_volumes_without_nulls :
    key => {
      size = local.ebs_volumes_swap_size
    } if lookup(value, "label", null) == "swap"
  }

  # remove nulls so merge() doesn't include them
  ebs_volumes_from_config_without_nulls = {
    for key1, value1 in local.ebs_volumes_from_config :
    key1 => {
      for key2, value2 in value1 : key2 => value2 if value2 != null
    }
  }

  # merge AMI and var.ebs_volume values, e.g. allow AMI settings to be overridden
  ebs_volume_names = var.ebs_volumes_copy_all_from_ami ? keys(merge(var.ebs_volumes, local.ami_block_device_mappings)) : keys(var.ebs_volumes)

  ebs_volumes = {
    for key in local.ebs_volume_names :
    key => merge(
      lookup(local.ebs_volumes_from_ami, key, {}),
      lookup(local.ebs_volumes_from_config_without_nulls, key, {}),
      lookup(local.ebs_volumes_swap, key, {}),
      lookup(local.ebs_volumes_without_nulls, key, {})
    )
  }

  ebs_volume_root = local.ebs_volumes[data.aws_ami.this.root_device_name]

  ebs_volumes_nonroot = {
    for key, value in local.ebs_volumes :
    key => value if key != data.aws_ami.this.root_device_name
  }

  user_data_args_ssm_params = {
    for key, value in var.ssm_parameters != null ? var.ssm_parameters : {} :
    "ssm_parameter_${key}" => aws_ssm_parameter.this[key].name
  }

  user_data_args_common = {
    volume_ids = join(" ", [for key, value in aws_ebs_volume.this : value.id])
  }

  user_data_args = merge(local.user_data_args_common, local.user_data_args_ssm_params, try(var.user_data_cloud_init.args, {}))

  user_data_part_count = [
    try(length(var.user_data_cloud_init.scripts), 0),
    try(length(var.user_data_cloud_init.write_files), 0)
  ]
}
