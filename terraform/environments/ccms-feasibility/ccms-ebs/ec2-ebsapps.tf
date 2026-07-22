module "oracle_ebs_apps" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/5674fd2
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/oracle-ec2?ref=5674fd2"
  count  = 2

  name          = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}"
  instance_profile_name = aws_iam_instance_profile.ebsapps.name

  instance_type      = local.application_data.accounts[local.environment].ec2_instance_type_ebsapps
  ami_id             = local.application_data.accounts[local.environment].ebsapps_ami_ids[count.index]
  key_name           = local.application_data.accounts[local.environment].key_name
  subnet_id          = local.private_subnets[count.index]
  security_group_ids = [aws_security_group.ebsapps.id]

  tags = merge(local.tags, {
    instance-role = "ebsapps"
    backup        = "true"
  })
}

# EBS Volumes
resource "aws_ebs_volume" "ebsapps_swap" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = 20
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-swap", device-name = "/dev/sdb" })
}

resource "aws_volume_attachment" "ebsapps_swap" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_swap]
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebsapps_swap[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_temp" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-temp", device-name = "/dev/sdc" })
}

resource "aws_volume_attachment" "ebsapps_temp" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_temp]
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.ebsapps_temp[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_home" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-home", device-name = "/dev/sdd" })
}

resource "aws_volume_attachment" "ebsapps_home" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_home]
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.ebsapps_home[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_export_home" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_exhome_size
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-export-home", device-name = "/dev/sdh" })
}

resource "aws_volume_attachment" "ebsapps_export_home" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_export_home]
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsapps_export_home[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_u01" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u01_size
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-u01", device-name = "/dev/sdi" })
}

resource "aws_volume_attachment" "ebsapps_u01" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_u01]
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.ebsapps_u01[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_u03" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u03_size
  type              = "gp3"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-u03", device-name = "/dev/sdj" })
}

resource "aws_volume_attachment" "ebsapps_u03" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_u03]
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.ebsapps_u03[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

resource "aws_ebs_volume" "ebsapps_stage" {
  count             = 2
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.oracle_ebs_apps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_stage_size
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags, { Name = "ec2-${local.component_name}-${local.env_label}-ebsapps-${count.index + 1}-stage", device-name = "/dev/sdk" })
}

resource "aws_volume_attachment" "ebsapps_stage" {
  count       = 2
  depends_on  = [aws_ebs_volume.ebsapps_stage]
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.ebsapps_stage[count.index].id
  instance_id = module.oracle_ebs_apps[count.index].instance_id
}

# ALB Target Group Attachments

resource "aws_lb_target_group_attachment" "ebsapps" {
  count            = 2
  target_group_arn = module.alb.target_group_arn
  target_id        = module.oracle_ebs_apps[count.index].instance_id
  port             = local.application_data.accounts[local.environment].tg_apps_port
}
