#Second instance in prod for failover
resource "aws_instance" "tariff_app_2" {
  count                       = local.environment == "production" ? 1 : 0
  ami                         = data.aws_ami.shared_ami.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.tariff_instance_profile.name
  instance_type               = "m5.2xlarge"
  key_name                    = aws_key_pair.key_pair_app.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_b.id
  user_data                   = <<EOF
            #!/bin/bash
            cd /tmp
            sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            EOF
  vpc_security_group_ids      = [module.tariff_app_prod_security_group[0].security_group_id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 20
  }
  /*
  ebs_block_device {
    device_name           = "xvde"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 100
    snapshot_id           = local.snapshot_id_xvde

  }
  ebs_block_device {
    device_name           = "xvdf"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 100
    snapshot_id           = local.snapshot_id_xvdf
  }
  ebs_block_device {
    device_name           = "xvdg"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 100
    snapshot_id           = local.snapshot_id_xvdg
  }

  ebs_block_device {
    device_name           = "xvdh"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 16
    snapshot_id           = local.snapshot_id_xvdh
  }
  ebs_block_device {
    device_name           = "xvdi"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
    snapshot_id           = local.snapshot_id_xvdi
  }
  */

  volume_tags = merge(tomap({
    "Name"               = "${local.application_name}-app2-root",
    "volume-attach-host" = "app2",
    "volume-mount-path"  = "/"
  }), local.tags)

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app2", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app2",
  }), local.tags)

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_ebs_volume" "tariff_app2_storage" {
  for_each          = local.environment == "production" ? { for v in local.tariffapp_volume_layout : v.device_name => v } : {}
  availability_zone = data.aws_subnet.private_subnets_b.availability_zone
  size              = each.value.size
  type              = "gp3"
  tags = merge(tomap({
    "Name"               = "${local.application_name}-app2-root",
    "volume-attach-host" = "app2",
    "volume-mount-path"  = "/"
  }), local.tags)
}

resource "aws_volume_attachment" "tariff_app2_storage_attachment" {
  for_each    = local.environment == "production" ? { for v in local.tariffapp_volume_layout : v.device_name => v } : {}
  device_name = each.key
  volume_id   = aws_ebs_volume.tariff_app2_storage[each.key].id
  instance_id = aws_instance.tariff_app_2[0].id
}
