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
            cd /tmp
            sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            EOF
  vpc_security_group_ids      = local.environment == "production" ? [module.tariff_app_prod_security_group[0].security_group_id] : [module.tariff_app_security_group[0].security_group_id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 20
    tags = merge(tomap({
      "Name"               = "${local.application_name}-app-root",
      "volume-attach-host" = "app",
      "volume-mount-path"  = "/",
    }), local.tags, local.environment != "production" ? tomap({ "backup" = "true" }) : tomap({}))
  }

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app",
    }), local.tags, local.environment != "production" ? tomap({ "backup" = "true" }) : tomap({})
  )

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_ebs_volume" "tariff_app_storage" {
  for_each          = { for v in local.tariffapp_volume_layout : v.device_name => v }
  availability_zone = data.aws_subnet.private_subnets_a.availability_zone
  size              = each.value.size
  type              = "gp3"
  tags = merge(tomap({
    "Name"               = "${local.application_name}-app-root",
    "volume-attach-host" = "app",
    "volume-mount-path"  = "/",
  }), local.tags, local.environment != "production" ? tomap({ "backup" = "true" }) : tomap({}))
}

resource "aws_volume_attachment" "tariff_app_storage_attachment" {
  for_each    = { for v in local.tariffapp_volume_layout : v.device_name => v }
  device_name = each.key
  volume_id   = aws_ebs_volume.tariff_app_storage[each.key].id
  instance_id = aws_instance.tariff_app.id
}
