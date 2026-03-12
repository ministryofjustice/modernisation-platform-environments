locals {
  userdata_kali = file("${path.module}/files/kali-ec2-update.sh")
}

######################################
### KALI EC2 INSTANCE
######################################

resource "aws_instance" "kali_app_instance_new" {
  count = local.environment == "preproduction" ? 1 : 0

  ami                         = "ami-002e3567c9c495d68"
  availability_zone           = "eu-west-2a"
  subnet_id                   = "subnet-063bec8ad1ef41959"
  instance_type               = "t2.micro"
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new[0].id
  user_data_replace_on_change = true
  user_data                   = local.userdata_kali

  vpc_security_group_ids = [
    aws_security_group.kali_sg[0].id
  ]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
    volume_type           = "gp3"

    tags = merge(
      local.tags,
      { Name = "${local.application_name}-kali-root-volume" }
    )
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name} Kali Server" },
    { "instance-scheduling" = "skip-scheduling" }
  )
}