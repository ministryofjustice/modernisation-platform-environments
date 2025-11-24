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
    volume_size = 30
    encrypted   = true
    tags = merge(tomap({
      Name = "TariffDB-${each.key}",
      }), local.tags
    )
  }
  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-db-${each.key}", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-db-${each.key}",
  }), local.tags)
  # Set security group where Instance will be created. This will also determine VPC
  vpc_security_group_ids = [module.tariff_db_prod_security_group[0].security_group_id, aws_security_group.tariff_db_prod_security_group[0].id]
  # vpc_security_group_ids = aws_security_group.tariff_db_prod_security_group[*].id
  key_name = aws_key_pair.key_pair_db[0].key_name

  /*
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
    volume_size           = 2000
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
*/
}
# CDI-274 refactoring ebs_block_device > aws_ebs_volume
data "aws_subnet" "subnet_az" {
  for_each = local.subnets_a_b_map
  id       = each.value
}

resource "aws_ebs_volume" "tariffdb_storage" {
  for_each = local.environment == "production" ? {
    for pair in setproduct(keys(local.subnets_a_b_map), local.tariffdb_volume_layout) :
    "${pair[0]}-${pair[1].device_name}" => {
      instance_key = pair[0]
      volume_data  = pair[1]
    }
  } : {}
  availability_zone = data.aws_subnet.subnet_az[each.value.instance_key].availability_zone
  size              = each.value.volume_data.size
  type              = "gp3"

  tags = merge(tomap({
    "Name" = "TariffDB-${each.value.instance_key}-volume-${each.value.volume_data.device_name}",
  }), local.tags)
}

resource "aws_volume_attachment" "tariffdb_attachment" {
  for_each = local.environment == "production" ? {
    for pair in setproduct(keys(local.subnets_a_b_map), local.tariffdb_volume_layout) :
    "${pair[0]}-${pair[1].device_name}" => {
      instance_key = pair[0]
      volume_data  = pair[1]
    }
  } : {}
  device_name = each.value.volume_data.device_name
  volume_id   = aws_ebs_volume.tariffdb_storage[each.key].id
  instance_id = aws_instance.tariffdb[each.value.instance_key].id
}

# AMI backup of tariffdb prior to CDI-274 refactor
resource "aws_ami_from_instance" "tariffdb_a_bkp" {
  count              = local.environment == "production" ? 1 : 0
  name               = "TariffDB_A_Bkp"
  source_instance_id = "i-030db90a2de02f56e"
  tags = {
    Name = "CDI-272-TariffDB-A-Backup"
  }
}
resource "aws_ami_from_instance" "tariffdb_b_bkp" {
  count              = local.environment == "production" ? 1 : 0
  name               = "TariffDB_B_Bkp"
  source_instance_id = "i-0939a0ee8fb520bc9"
  tags = {
    Name = "CDI-272-TariffDB-A-Backup"
  }
}

# rescue instance
resource "aws_instance" "tariffdbrescue" {
  count                = local.environment == "production" ? 1 : 0
  ami                  = "ami-03f3a22c5f8f5ef58"
  instance_type        = "t3.small"
  subnet_id            = "subnet-02cd9ee24bdc797e4"
  iam_instance_profile = aws_iam_instance_profile.tariff_instance_profile.name
  root_block_device {
    volume_size = 8
    encrypted   = true
    tags = {
      Name = "TariffDB-Rescue",
    }
  }
  tags = {
    Name = "TariffDB-Rescue"
  }
  vpc_security_group_ids = [aws_security_group.tariff_db_prod_security_group[0].id]
}