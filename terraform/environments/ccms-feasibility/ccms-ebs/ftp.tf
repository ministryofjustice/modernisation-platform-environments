module "ftp" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/646ef03
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/oracle-ec2?ref=646ef03"

  name                  = "${local.component_name}-${local.env_label}-ftp"
  instance_profile_name = aws_iam_instance_profile.ftp.name

  instance_type      = local.application_data.accounts[local.environment].ec2_instance_type_ftp
  ami_id             = local.application_data.accounts[local.environment].ftp_ami_id
  key_name           = local.application_data.accounts[local.environment].key_name
  subnet_id          = data.aws_subnet.private_subnets_a.id
  security_group_ids = [aws_security_group.ftp.id]

  user_data = base64encode(templatefile("./templates/ec2_user_data_ftp.sh", {
    ftp_inbound_bucket  = module.s3_inbound.bucket.id
    ftp_outbound_bucket = module.s3_outbound.bucket.id
  }))

  tags = merge(local.tags, {
    instance-role       = "ftp"
    backup              = "true"
    instance-scheduling = "skip-scheduling"
  })
}

# EBS Volumes

resource "aws_ebs_volume" "ftp_data" {
  lifecycle { ignore_changes = [kms_key_id] }
  availability_zone = module.ftp.availability_zone
  size              = local.application_data.accounts[local.environment].ftp_data_volume_size
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags              = merge(local.tags, { Name = "${local.component_name}-${local.env_label}-ftp-data", device-name = "/dev/sdb" })
}

resource "aws_volume_attachment" "ftp_data" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ftp_data.id
  instance_id = module.ftp.instance_id
}
