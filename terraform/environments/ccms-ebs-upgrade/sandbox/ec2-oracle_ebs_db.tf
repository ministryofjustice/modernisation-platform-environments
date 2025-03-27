resource "aws_instance" "ec2_oracle_ebs" {
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  ami                         = local.application_data.accounts[local.environment].ebsdb_ami_id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_sandbox.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  cpu_options {
    core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsdb
    threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsdb
  }
  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}
  lifecycle {
    ignore_changes = [
      cpu_options["core_count"],
      ebs_block_device,
      ebs_optimized,
      user_data,
      user_data_replace_on_change
    ]
  }
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_ebs.sh", {
    environment = "${local.environment}"
    hostname    = "ebs"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = lower(format("ccms-ebs-%s-ebsdb", local.component_name)) },
    { component = local.component_name },
    { instance-role = local.application_data.accounts[local.environment].instance_role_ebsdb },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" },
    { OracleDbLTS-ManagedInstance = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_sandbox]
}

#          onditional
# /device  C /mount_point
# --------+-+------------
# /dev/sda   /      (AMI)
# /dev/sdb   swap   (AMI)
# /dev/sdc   /temp  (AMI)
# /dev/sdd   /home  (AMI)
# /dev/sdh   /export/home
# /dev/sdi   /u01
# /dev/sdj   /CCMS/EBS/arch
# /dev/sdl   /CCMS/EBS/redoA
# /dev/sdm   /CCMS/EBS/techst
# /dev/sdn   /backup
# /dev/sdo v /dbf2            # commented out
# /dev/sdo   /CCMS/EBS/redoB
# /dev/sdp   /CCMS/EBS/diag
# /dev/sdq   /CCMS/EBS/dbf01
# /dev/sdr   /CCMS/EBS/dbf02
# /dev/sds   /CCMS/EBS/dbf03
# /dev/sdt   /CCMS/EBS/dbf04
# /dev/sdx   swap2
# /dev/sdy v /backup_prod
# /dev/sdz v /backup_clone

resource "aws_ebs_volume" "export_home" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_exhome
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "export-home")) },
    { device-name = "/dev/sdh" }
  )
}

resource "aws_volume_attachment" "export_home_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "u01" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_u01
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "u01")) },
    { device-name = "/dev/sdi" }
  )
}

resource "aws_volume_attachment" "u01_att" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "arch" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_arch
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "arch")) },
    { device-name = "/dev/sdj" }
  )
}

resource "aws_volume_attachment" "arch_att" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "redoA" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoA
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "redoA")) },
    { device-name = "/dev/sdl" }
  )
}

resource "aws_volume_attachment" "redoA_att" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "techst" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_techst
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "techst")) },
    { device-name = "/dev/sdm" }
  )
}

resource "aws_volume_attachment" "techst_att" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "backup" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_backup
  type              = local.application_data.accounts[local.environment].ebs_type_ebsdb_backup
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "backup")) },
    { device-name = "/dev/sdn" }
  )
}

resource "aws_volume_attachment" "backup_att" {
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.backup.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

# resource "aws_ebs_volume" "backup_prod" {
#   lifecycle {
#     ignore_changes = [kms_key_id]
#   }
#   availability_zone = "eu-west-2a"
#   count             = length(local.application_data.accounts[local.environment].ebs_backup_prod_snapshot_id) > 0 ? 1 : 0
#   size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_backup
#   type              = local.application_data.accounts[local.environment].ebs_type_ebsdb_backup
#   snapshot_id       = length(local.application_data.accounts[local.environment].ebs_backup_prod_snapshot_id) > 0 ? local.application_data.accounts[local.environment].ebs_backup_prod_snapshot_id : null
#   iops              = 3000
#   encrypted         = true
#   kms_key_id        = data.aws_kms_key.ebs_shared.key_id
#   tags = merge(local.tags,
#     { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "backup-prod")) },
#     { device-name = "/dev/sdy" }
#   )
# }

# resource "aws_volume_attachment" "backup_prod_att" {
#   count       = length(local.application_data.accounts[local.environment].ebs_backup_prod_snapshot_id) > 0 ? 1 : 0
#   device_name = "/dev/sdy"
#   volume_id   = aws_ebs_volume.backup_prod[0].id
#   instance_id = aws_instance.ec2_oracle_ebs.id
# }

resource "aws_ebs_volume" "redoB" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoB
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "redoB")) },
    { device-name = "/dev/sdo" }
  )
}

resource "aws_volume_attachment" "redoB_att" {
  depends_on = [
    aws_ebs_volume.redoB
  ]
  device_name = "/dev/sdo"
  volume_id   = aws_ebs_volume.redoB.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "diag" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_diag
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "diag")) },
    { device-name = "/dev/sdp" }
  )
}

resource "aws_volume_attachment" "diag_att" {
  depends_on = [
    aws_ebs_volume.diag
  ]
  device_name = "/dev/sdp"
  volume_id   = aws_ebs_volume.diag.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "dbf01" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf01
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf01
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "dbf01")) },
    { device-name = "/dev/sdq" }
  )
}

resource "aws_volume_attachment" "dbf01_att" {
  depends_on = [
    aws_ebs_volume.dbf01
  ]
  device_name = "/dev/sdq"
  volume_id   = aws_ebs_volume.dbf01.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "dbf02" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf02
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf02
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "dbf02")) },
    { device-name = "/dev/sdr" }
  )
}

resource "aws_volume_attachment" "dbf02_att" {
  depends_on = [
    aws_ebs_volume.dbf02
  ]
  device_name = "/dev/sdr"
  volume_id   = aws_ebs_volume.dbf02.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "dbf03" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf03
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf03
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "dbf03")) },
    { device-name = "/dev/sds" }
  )
}

resource "aws_volume_attachment" "dbf03_att" {
  depends_on = [
    aws_ebs_volume.dbf03
  ]
  device_name = "/dev/sds"
  volume_id   = aws_ebs_volume.dbf03.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "dbf04" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf04
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf04
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.component_name, local.application_data.accounts[local.environment].instance_role_ebsdb, "dbf04")) },
    { device-name = "/dev/sdt" }
  )
}

resource "aws_volume_attachment" "dbf04_att" {
  depends_on = [
    aws_ebs_volume.dbf04
  ]
  device_name = "/dev/sdt"
  volume_id   = aws_ebs_volume.dbf04.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
