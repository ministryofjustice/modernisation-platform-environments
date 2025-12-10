######################################
### EC2 EBS VOLUMES AND ATTACHMENTS
######################################
resource "aws_ebs_volume" "EC2ServerVolumeORAHOME_new" {
  count             = contains(["test", "preproduction"], local.environment) ? 1 : 0
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServerVolumeORAHOME" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume01_new" {
  count       = contains(["test", "preproduction"], local.environment) ? 1 : 0
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME_new[0].id
  instance_id = aws_instance.oas_app_instance_new[0].id
}

resource "aws_ebs_volume" "EC2ServerVolumeSTAGE_new" {
  count             = contains(["test", "preproduction"], local.environment) ? 1 : 0
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].stageesize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].stage_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServerVolumeSTAGE" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume02_new" {
  count       = contains(["test", "preproduction"], local.environment) ? 1 : 0
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.EC2ServerVolumeSTAGE_new[0].id
  instance_id = aws_instance.oas_app_instance_new[0].id
}
