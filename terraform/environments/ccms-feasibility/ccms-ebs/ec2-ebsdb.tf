module "oracle_ebs_db" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/5674fd2
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/oracle-ec2?ref=5674fd2"

  name          = "ec2-${local.component_name}-${local.env_label}-ebsdb"
  instance_profile_name = aws_iam_instance_profile.ebsdb.name

  instance_type      = local.application_data.accounts[local.environment].ec2_instance_type_ebsdb
  ami_id             = local.application_data.accounts[local.environment].ebsdb_ami_id
  key_name           = local.application_data.accounts[local.environment].key_name
  subnet_id          = data.aws_subnet.data_subnets_a.id
  security_group_ids = [aws_security_group.ebsdb.id]

  tags = merge(local.tags, {
    instance-role = "ebsdb"
    backup        = "true"
  })
}

# EBS Volumes

resource "aws_ebs_volume" "ebsdb_swap" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_swap
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_swap
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-swap", device-name = "/dev/sdb" })
}

resource "aws_volume_attachment" "ebsdb_swap" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebsdb_swap.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_export_home" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_exhome
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-export-home", device-name = "/dev/sdh" })
}

resource "aws_volume_attachment" "ebsdb_export_home" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsdb_export_home.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_u01" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_u01
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-u01", device-name = "/dev/sdi" })
}

resource "aws_volume_attachment" "ebsdb_u01" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.ebsdb_u01.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_arch" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_arch
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-arch", device-name = "/dev/sdj" })
}

resource "aws_volume_attachment" "ebsdb_arch" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.ebsdb_arch.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_dbf" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-dbf", device-name = "/dev/sdk" })
}

resource "aws_volume_attachment" "ebsdb_dbf" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.ebsdb_dbf.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_dbf01" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf01
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf01
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-dbf01", device-name = "/dev/sde" })
}

resource "aws_volume_attachment" "ebsdb_dbf01" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.ebsdb_dbf01.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_dbf02" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf02
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf02
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-dbf02", device-name = "/dev/sdf" })
}

resource "aws_volume_attachment" "ebsdb_dbf02" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebsdb_dbf02.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_dbf03" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf03
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf03
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-dbf03", device-name = "/dev/sdg" })
}

resource "aws_volume_attachment" "ebsdb_dbf03" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.ebsdb_dbf03.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_dbf04" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf04
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebs_iops_ebsdb_dbf04
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-dbf04", device-name = "/dev/sdt" })
}

resource "aws_volume_attachment" "ebsdb_dbf04" {
  device_name = "/dev/sdt"
  volume_id   = aws_ebs_volume.ebsdb_dbf04.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_redoA" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoA
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-redoA", device-name = "/dev/sdl" })
}

resource "aws_volume_attachment" "ebsdb_redoA" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.ebsdb_redoA.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_techst" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_techst
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-techst", device-name = "/dev/sdm" })
}

resource "aws_volume_attachment" "ebsdb_techst" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.ebsdb_techst.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_backup" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_backup
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-backup", device-name = "/dev/sdn" })
}

resource "aws_volume_attachment" "ebsdb_backup" {
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.ebsdb_backup.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_redoB" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoB
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-redoB", device-name = "/dev/sdo" })
}

resource "aws_volume_attachment" "ebsdb_redoB" {
  device_name = "/dev/sdo"
  volume_id   = aws_ebs_volume.ebsdb_redoB.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_diag" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_diag
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-diag", device-name = "/dev/sdp" })
}

resource "aws_volume_attachment" "ebsdb_diag" {
  device_name = "/dev/sdp"
  volume_id   = aws_ebs_volume.ebsdb_diag.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_appshare" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_appshare
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id           = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-appshare", device-name = "/dev/sdq" })
}

resource "aws_volume_attachment" "ebsdb_appshare" {
  device_name = "/dev/sdq"
  volume_id   = aws_ebs_volume.ebsdb_appshare.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_home" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_home
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-home", device-name = "/dev/sdr" })
}

resource "aws_volume_attachment" "ebsdb_home" {
  device_name = "/dev/sdr"
  volume_id   = aws_ebs_volume.ebsdb_home.id
  instance_id = module.oracle_ebs_db.instance_id
}

resource "aws_ebs_volume" "ebsdb_temp" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_db.availability_zone
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_temp
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsdb-temp", device-name = "/dev/sds" })
}

resource "aws_volume_attachment" "ebsdb_temp" {
  device_name = "/dev/sds"
  volume_id   = aws_ebs_volume.ebsdb_temp.id
  instance_id = module.oracle_ebs_db.instance_id
}
