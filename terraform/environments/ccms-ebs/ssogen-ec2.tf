resource "aws_instance" "ec2_ssogen" {
  count                  = local.application_data.accounts[local.environment].ssogen_no_instances
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ssogen
  ami                    = local.application_data.accounts[local.environment].ssogen_ami_id
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ssogen_sg.id]
  subnet_id              = local.private_subnets[count.index]
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssogen_instance_profile.name

  cpu_options {
    core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ssogen
    threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ssogen
  }

  lifecycle {
    ignore_changes = [
      ebs_block_device,
      ebs_optimized,
      user_data,
      user_data_replace_on_change,
      tags
    ]
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }
 
  user_data_replace_on_change = false
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

