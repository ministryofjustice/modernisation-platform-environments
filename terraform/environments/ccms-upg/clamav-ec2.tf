module "clamav" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/f3ab28c
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ec2?ref=f3ab28c"

  name                  = "${local.application_name}-clamav"
  instance_profile_name = aws_iam_instance_profile.clamav.name

  instance_type      = local.application_data.accounts[local.environment].clamav_ec2_instance_type
  ami_id             = local.application_data.accounts[local.environment].clamav_ami_id
  subnet_id          = data.aws_subnet.private_subnets_a.id
  security_group_ids = [aws_security_group.clamav.id]
  monitoring         = true
  ebs_optimized      = true

  user_data = base64encode(templatefile("./templates/user_data_clamav.sh", {
    hostname = "clamav"
  }))

  tags = merge(local.tags, {
    instance-role       = local.application_data.accounts[local.environment].clamav_instance_role
    instance-scheduling = "skip-scheduling"
    backup              = "true"
  })
}

# EBS Volumes

resource "aws_ebs_volume" "clamav_swap" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.clamav.availability_zone
  size              = 50
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags              = merge(local.tags, { Name = "${local.application_name}-clamav-swap", device-name = "/dev/sdb" })
}

resource "aws_volume_attachment" "clamav_swap" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.clamav_swap.id
  instance_id = module.clamav.instance_id
}
