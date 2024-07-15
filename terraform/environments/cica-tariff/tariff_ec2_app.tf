resource "aws_key_pair" "key_pair_app" {
  key_name   = lower(format("%s-%s-key", local.application_name, local.environment))
  public_key = local.pubkey[local.environment]
  tags = merge(tomap({
    "Name" = lower(format("ec2-%s-%s-app", local.application_name, local.environment))
  }), local.tags)
}



resource "aws_instance" "tariff_app" {
  ami                         = data.aws_ami.shared_ami.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.tariff_instance_profile.name
  instance_type               = "m5.2xlarge"
  key_name                    = aws_key_pair.key_pair_app.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  user_data                   = <<EOF
            #!/bin/bash
            yum update -y
            yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
            systemctl status amazon-ssm-agent
            EOF
  vpc_security_group_ids      = [aws_security_group.tariff_app_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 20
  }

  volume_tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-root",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sda1",
    "volume-mount-path"    = "/"
  }), local.tags)

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
