######################################
### EC2 UPGRADE TEST INSTANCE
### This instance is for testing Oracle Linux 7.9 to 8.10 upgrade using Leapp
######################################

######################################
### EC2 Network Interface (ENI) - UPGRADE TEST
######################################
resource "aws_network_interface" "oas_eni_upgrade_test" {
  count           = contains(["development"], local.environment) ? 1 : 0
  subnet_id       = data.aws_subnet.private_subnets_a.id
  private_ips     = ["10.26.56.149"]
  security_groups = [aws_security_group.ec2_sg[0].id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-upgrade-test-eni" }
  )
}

######################################
### EC2 INSTANCE - UPGRADE TEST
######################################
resource "aws_instance" "oas_app_instance_upgrade_test" {
  count = contains(["development"], local.environment) ? 1 : 0

  ami                         = "ami-02e43e2fc8a2cf14a"
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  key_name                    = aws_key_pair.ec2_key_pair[0].key_name
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new[0].id
  user_data_replace_on_change = false
  user_data                   = base64encode(local.userdata_new)

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.oas_eni_upgrade_test[0].id
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = true
    volume_size           = 40
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-upgrade-test-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server - Upgrade Test" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" },
    { "Purpose" = "OL 7.9 to 8.10 Leapp upgrade testing" }
  )
}

######################################
### EBS VOLUMES - UPGRADE TEST
######################################
resource "aws_ebs_volume" "EC2ServerVolumeORAHOME_upgrade_test" {
  count             = contains(["development"], local.environment) ? 1 : 0
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
    { "Name" = "${local.application_name}-upgrade-test-EC2ServerVolumeORAHOME" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume01_upgrade_test" {
  count       = contains(["development"], local.environment) ? 1 : 0
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME_upgrade_test[0].id
  instance_id = aws_instance.oas_app_instance_upgrade_test[0].id
}

resource "aws_ebs_volume" "EC2ServerVolumeSTAGE_upgrade_test" {
  count             = contains(["development"], local.environment) ? 1 : 0
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
    { "Name" = "${local.application_name}-upgrade-test-EC2ServerVolumeSTAGE" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume02_upgrade_test" {
  count       = contains(["development"], local.environment) ? 1 : 0
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.EC2ServerVolumeSTAGE_upgrade_test[0].id
  instance_id = aws_instance.oas_app_instance_upgrade_test[0].id
}
