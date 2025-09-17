#keypair for prod db

resource "aws_key_pair" "key_pair_db" {
  count      = local.environment == "production" ? 1 : 0
  key_name   = lower(format("%s-%s-database-key", local.application_name, local.environment))
  public_key = local.pubkey["database"]
  tags = merge(tomap({
    "Name" = lower(format("ec2-%s-%s-database", local.application_name, local.environment))
  }), local.tags)
}




# Create AWS EC2 instance, specifies ami and type. Also Public key to use for pw
resource "aws_instance" "tariffdb" {
  for_each = local.environment == "production" ? local.subnets_a_b_map : {}
  ami      = data.aws_ami.shared_db_ami[0].id
  #Ignore changes to most recent ami from data filter, as this would destroy existing instance.
  lifecycle {
    ignore_changes = [ami]
  }
  instance_type = "m5.2xlarge"
  subnet_id     = each.value
  # private_ip           = var.private_ip
  iam_instance_profile = aws_iam_instance_profile.tariff_instance_profile.name
  root_block_device {
    volume_size = 20
    encrypted   = true
    tags = {
      Name = "TariffDB-${each.key}"
    }
  }
  tags = {
    Name = "TariffDB-${each.key}"
  }
  # Set security group where Instance will be created. This will also determine VPC
  vpc_security_group_ids = aws_security_group.tariff_db_prod_security_group[*].id
  key_name               = aws_key_pair.key_pair_db[0].key_name


  ebs_block_device {
    device_name           = "xvde"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 100
    snapshot_id           = local.snapshot_id_xvde_db

  }
  ebs_block_device {
    device_name           = "xvdf"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 900
    snapshot_id           = local.snapshot_id_xvdf_db
  }
  ebs_block_device {
    device_name           = "xvdg"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 100
    snapshot_id           = local.snapshot_id_xvdg_db
  }

  ebs_block_device {
    device_name           = "xvdh"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 16
    snapshot_id           = local.snapshot_id_xvdh_db
  }
  ebs_block_device {
    device_name           = "xvdi"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
    snapshot_id           = local.snapshot_id_xvdi_db
  }
  ebs_block_device {
    device_name           = "xvdj"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 8
    snapshot_id           = local.snapshot_id_xvdj_db
  }
  ebs_block_device {
    device_name           = "xvdk"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 1
    snapshot_id           = local.snapshot_id_xvdk_db
  }
  ebs_block_device {
    device_name           = "xvdl"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 200
    snapshot_id           = local.snapshot_id_xvdl_db
  }
  ebs_block_device {
    device_name           = "xvdm"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 500
    snapshot_id           = local.snapshot_id_xvdm_db
  }
  ebs_block_device {
    device_name           = "xvdn"
    delete_on_termination = true
    encrypted             = true
    volume_size           = 500
    snapshot_id           = local.snapshot_id_xvdn_db
  }
}
