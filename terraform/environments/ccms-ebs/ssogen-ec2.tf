locals {
  is_development = local.environment == "development"
}

resource "aws_instance" "ec2_ssogen" {
  count = local.is_development ? local.application_data.accounts[local.environment].ssogen_no_instances : 0

  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ssogen
  ami                         = local.application_data.accounts[local.environment].ssogen_ami_id
  key_name                    = aws_key_pair.ssogen[0].key_name
  vpc_security_group_ids      = [aws_security_group.ssogen_sg[0].id]
  subnet_id                   = local.private_subnets[count.index]
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssogen_instance_profile[0].name

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 60
    volume_type = "gp2"
    encrypted   = true
  }

  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/ec2_user_data_ssogen.sh", {
    hostname = "ssogen-${count.index + 1}"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    local.tags,
    { Name = "ec2-ccms-ebs-development-ssogen-${count.index + 1}" },
    { "instance-role" = local.application_data.accounts[local.environment].instance_role_ssogen },
    { "instance-scheduling" = local.application_data.accounts[local.environment]["instance-scheduling"] },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ssogen_sg]
}
