resource "aws_instance" "ec2_ebsapps" {
  count                       = local.application_data.accounts[local.environment].ebsapps_no_instances
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsapps
  ami                         = local.application_data.accounts[local.environment]["ebsapps_ami_id-${count.index + 1}"]
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_sandbox.id]
  subnet_id                   = local.private_subnets[count.index]
  monitoring                  = true
  ebs_optimized               = local.application_data.accounts[local.environment].ebs_optimized
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  cpu_options {
    core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsapps
    threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsapps
  }
  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  lifecycle {
    ignore_changes = [
      ebs_block_device,
      user_data,
      user_data_replace_on_change
    ]
  }
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_ebs_apps.sh", {
    hostname = "ebs-apps-sandbox"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # AMI ebs mappings from /dev/sd[a-d]
  # root
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "root")) },
      { component = local.component_name },
      { device-name = "/dev/sda1" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("ccms-ebs-%s-ebsapps-%s", local.component_name, count.index + 1)) },
    { component = local.component_name },
    { instance-role = local.application_data.accounts[local.environment].instance_role_ebsapps },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_sandbox]
}

resource "aws_ebs_volume" "swap" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 20
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "swap")) },
    { component = local.component_name },
    { device-name = "/dev/sdb" }
  )
}

resource "aws_volume_attachment" "swap_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.swap]
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.swap[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "temp" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "temp")) },
    { component = local.component_name },
    { device-name = "/dev/sdc" }
  )
}

resource "aws_volume_attachment" "temp_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.temp]
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.temp[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "home" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "home")) },
    { component = local.component_name },
    { device-name = "/dev/sdd" }
  )
}

resource "aws_volume_attachment" "home_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.home]
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.home[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_export_home" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_exhome_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "export-home")) },
    { component = local.component_name },
    { device-name = "/dev/sdh" }
  )
}

resource "aws_volume_attachment" "apps_export_home_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_export_home]
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.apps_export_home[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_u01" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u01_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "u01")) },
    { component = local.component_name },
    { device-name = "/dev/sdi" }
  )
}

resource "aws_volume_attachment" "apps_u01_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_u01]
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.apps_u01[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_u03" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u03_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "u03")) },
    { component = local.component_name },
    { device-name = "/dev/sdj" }
  )
}

resource "aws_volume_attachment" "apps_u03_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_u03]
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.apps_u03[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "stage" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_stage_size
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "stage")) },
    { component = local.component_name },
    { device-name = "/dev/sdk" }
  )
}

resource "aws_volume_attachment" "stage_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.stage]
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.stage[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

