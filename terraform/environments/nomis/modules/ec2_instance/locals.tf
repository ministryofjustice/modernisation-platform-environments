locals {
  name_split = split("-", var.name)

  default_tags = {
    server-type       = join("-", slice(local.name_split, 1, length(local.name_split)))
    nomis-environment = local.name_split[0]
    always_on         = lookup(var.tags, "always-on", true) # backward compat.
    server-name       = var.name
  }
  tags = merge(local.default_tags, var.tags)

  ami_block_device_mappings = {
    for bdm in data.aws_ami.this.block_device_mappings : bdm.device_name => bdm
  }

  ami_block_device_mappings_root = local.ami_block_device_mappings[data.aws_ami.this.root_device_name]

  ami_block_device_mappings_nonroot = {
    for key, value in local.ami_block_device_mappings :
    key => value if key != data.aws_ami.this.root_device_name
  }

  ebs_volumes_from_ami = {
    for key, value in local.ami_block_device_mappings :
    key => {
      snapshot_id = value.ebs.snapshot_id
      iops        = value.ebs.iops
      throughput  = value.ebs.throughput
      size        = value.ebs.volume_size
      type        = value.ebs.volume_type
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
  ebs_volume_names = keys(merge(var.ebs_volumes, local.ami_block_device_mappings_nonroot))
  ebs_volumes = {
    for key in local.ebs_volume_names :
    key => merge(
      try(local.ebs_volumes_from_ami[key], {}),
      try(local.ebs_volumes_from_config[key], {}),
      try(var.ebs_volumes[key], {})
    )
  }

  user_data_args_ssm_params = {
    for key, value in var.ssm_parameters :
    "ssm_parameter_${key}" => aws_ssm_parameter.this[key].name
  }

  user_data_args_common = {
    branch               = var.branch == "" ? "main" : var.branch
    ansible_repo         = var.ansible_repo == null ? "" : var.ansible_repo
    ansible_repo_basedir = var.ansible_repo_basedir == null ? "" : var.ansible_repo_basedir
    volume_ids           = join(" ", [for key, value in aws_ebs_volume.this : value.id])
  }

  user_data_args = merge(local.user_data_args_common, local.user_data_args_ssm_params, try(var.user_data.args, {}))
}
