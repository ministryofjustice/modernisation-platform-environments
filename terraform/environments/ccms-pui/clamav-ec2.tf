resource "aws_instance" "ec2_clamav" {
  instance_type               = local.application_data.accounts[local.environment].ec2_instance_type_clamav
  ami                         = local.application_data.accounts[local.environment].clamav_ami_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg_clamav.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = true
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_clamav.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  lifecycle {
    ignore_changes = [
      ebs_block_device,
      root_block_device,
      ebs_optimized,
      user_data,
      user_data_replace_on_change,
      tags
    ]
  }

  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/user_data_clamav.sh", {
    hostname = "clamav"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    iops        = 3000
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_clamav, "root")) },
      { device-name = "/dev/sda1" }
    )
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_clamav, "swap")) },
      { device-name = "/dev/sdb" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("clamav-%s", local.environment)) },
    { instance-role = local.application_data.accounts[local.environment].instance_role_clamav },
    { instance-scheduling = "skip-scheduling" },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_clamav]
}
