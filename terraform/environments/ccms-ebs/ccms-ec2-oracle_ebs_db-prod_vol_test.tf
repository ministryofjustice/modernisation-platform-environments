# Snapshots of EBS DB volumes in ccms-ebs-production attached to EBS DB in ccms-ebs-test.
# Sizes and IOPS of these volumes have to match production values, hence hardcoded reference.
# Device IDs start from /dev/sdaa, up to /dev/sdaj (normal volumes occupy ids up to /dev/sdz).
# 
#           snap-0f26fe4c50464458e - /
# /dev/sdaa snap-04dc8385f2eea4c46 + /backup
# /dev/sdab snap-Oc8fe8d91964afa0d + /CCMS/EBSPROD/arch
# /dev/sdac snap-0443ae13d35ca9706 + /CCMS/EBSPROD/dbf01
# /dev/sdad snap-02d677a1195040bd5 + /CCMS/EBSPROD/dbf02
# /dev/sdae snap-0fb308e92c6ce4ecc + /CCMS/EBSPROD/dbf03
# /dev/sdaf snap-0728d350b9079f044 + /CCMS/EBSPROD/dbf04
# /dev/sdag snap-099dc03400be4bbf9 + /CCMS/EBSPROD/diag
# /dev/sdah snap-Oa254db0b5290dba3 + /CCMS/EBSPROD/redoA
# /dev/sdai snap-093f8f3c22aa5c13b + /CCMS/EBSPROD/redoB
# /dev/sdaj snap-01bdd99b165c0d8f4 + /CCMS/EBSPROD/techst
#           snap-02f666549819240a2 - /export/home
#           snap-05eaf45bd409c4c9e - /home
#           snap-06aa8b3fb0d3c45e7 - /temp
#           snap-06d8adeb781e60d40 - /u01

# /dev/sdaa snap-04dc8385f2eea4c46 + /backup
resource "aws_ebs_volume" "prod_db_backup" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-04dc8385f2eea4c46"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_backup
  type              = local.application_data.accounts["production"].ebs_type_ebsdb_backup
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_backup")) },
    { device-name = "/dev/sdaa" }
  )
}

resource "aws_volume_attachment" "att_prod_db_backup" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdaa"
  volume_id   = aws_ebs_volume.prod_db_backup[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdab snap-Oc8fe8d91964afa0d + /CCMS/EBSPROD/arch
resource "aws_ebs_volume" "prod_db_arch" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-Oc8fe8d91964afa0d"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_arch
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_arch")) },
    { device-name = "/dev/sdab" }
  )
}

resource "aws_volume_attachment" "att_prod_db_arch" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdab"
  volume_id   = aws_ebs_volume.prod_db_arch[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdac snap-0443ae13d35ca9706 + /CCMS/EBSPROD/dbf01
resource "aws_ebs_volume" "prod_db_dbf01" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-0443ae13d35ca9706"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_dbf01
  type              = "io2"
  iops              = local.application_data.accounts["production"].ebs_iops_ebsdb_dbf01
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_dbf01")) },
    { device-name = "/dev/sdac" }
  )
}

resource "aws_volume_attachment" "att_prod_db_dbf01" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdac"
  volume_id   = aws_ebs_volume.prod_db_dbf01[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdad snap-02d677a1195040bd5 + /CCMS/EBSPROD/dbf02
resource "aws_ebs_volume" "prod_db_dbf02" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-02d677a1195040bd5"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_dbf02
  type              = "io2"
  iops              = local.application_data.accounts["production"].ebs_iops_ebsdb_dbf02
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_dbf02")) },
    { device-name = "/dev/sdad" }
  )
}

resource "aws_volume_attachment" "att_prod_db_dbf02" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdad"
  volume_id   = aws_ebs_volume.prod_db_dbf02[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdae snap-0fb308e92c6ce4ecc + /CCMS/EBSPROD/dbf03
resource "aws_ebs_volume" "prod_db_dbf03" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-0fb308e92c6ce4ecc"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_dbf03
  type              = "io2"
  iops              = local.application_data.accounts["production"].ebs_iops_ebsdb_dbf03
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_dbf03")) },
    { device-name = "/dev/sdae" }
  )
}

resource "aws_volume_attachment" "att_prod_db_dbf03" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdae"
  volume_id   = aws_ebs_volume.prod_db_dbf03[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdaf snap-0728d350b9079f044 + /CCMS/EBSPROD/dbf04
resource "aws_ebs_volume" "prod_db_dbf04" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-0728d350b9079f044"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_dbf04
  type              = "io2"
  iops              = local.application_data.accounts["production"].ebs_iops_ebsdb_dbf04
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_dbf04")) },
    { device-name = "/dev/sdaf" }
  )
}

resource "aws_volume_attachment" "att_prod_db_dbf04" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdaf"
  volume_id   = aws_ebs_volume.prod_db_dbf04[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdag snap-099dc03400be4bbf9 + /CCMS/EBSPROD/diag
resource "aws_ebs_volume" "prod_db_diag" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-099dc03400be4bbf9"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_diag
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_diag")) },
    { device-name = "/dev/sdag" }
  )
}

resource "aws_volume_attachment" "att_prod_db_diag" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdag"
  volume_id   = aws_ebs_volume.prod_db_diag[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdah snap-Oa254db0b5290dba3 + /CCMS/EBSPROD/redoA
resource "aws_ebs_volume" "prod_db_redoa" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-Oa254db0b5290dba3"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_redoA
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_redoa")) },
    { device-name = "/dev/sdah" }
  )
}

resource "aws_volume_attachment" "att_prod_db_redoa" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdah"
  volume_id   = aws_ebs_volume.prod_db_redoa[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdai snap-093f8f3c22aa5c13b + /CCMS/EBSPROD/redoB
resource "aws_ebs_volume" "prod_db_redob" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-093f8f3c22aa5c13b"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_redoB
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_redob")) },
    { device-name = "/dev/sdai" }
  )
}

resource "aws_volume_attachment" "att_prod_db_redob" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdai"
  volume_id   = aws_ebs_volume.prod_db_redob[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}


# /dev/sdaj snap-01bdd99b165c0d8f4 + /CCMS/EBSPROD/techst
resource "aws_ebs_volume" "prod_db_techst" {
  count       = local.is-test ? 1 : 0
  snapshot_id = "snap-01bdd99b165c0d8f4"
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts["production"].ebs_size_ebsdb_techst
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ebsdb, "prod_db_techst")) },
    { device-name = "/dev/sdaj" }
  )
}

resource "aws_volume_attachment" "att_prod_db_techst" {
  count       = local.is-test ? 1 : 0
  device_name = "/dev/sdaj"
  volume_id   = aws_ebs_volume.prod_db_techst[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
