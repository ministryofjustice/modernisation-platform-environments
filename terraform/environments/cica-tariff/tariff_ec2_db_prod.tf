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
    for pair in setproduct(keys(local.subnets_a_b_map), local.tarrifdb_volume_layout) :
    "${pair[0]}-${pair[1].device_name}" => {
      instance_key = pair[0]
      volume_data  = pair[1]
    }
  } : {}
  availability_zone = data.aws_subnet.subnet_az[each.value.instance_key].availability_zone
  size              = each.value.volume_data.size
  type              = "gp3"
  tags = {
    Name      = "TariffDB-${each.value.instance_key}-volume-${each.value.volume_data.device_name}"
  }
}

resource "aws_volume_attachment" "tariffdb_attachment" {
  for_each = local.environment == "production" ? {
    for pair in setproduct(keys(local.subnets_a_b_map), local.tarrifdb_volume_layout) :
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

# Import volumes + attachments TariffDB subnet A
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvde"]
  id = "vol-0709994329a0f926b"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvde"]
  id = "xvde:vol-0709994329a0f926b:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdf"]
  id = "vol-074b0406dd536d13c"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdf"]
  id = "xvdf:vol-074b0406dd536d13c:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdg"]
  id = "vol-06aac65b8ceb9ec33"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdg"]
  id = "xvdg:vol-06aac65b8ceb9ec33:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdh"]
  id = "vol-05527dd7dc6fbbf71"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdh"]
  id = "xvdh:vol-05527dd7dc6fbbf71:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdi"]
  id = "vol-0e527f79fac9663ab"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdi"]
  id = "xvdi:vol-0e527f79fac9663ab:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdj"]
  id = "vol-040a345567e8228f6"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdj"]
  id = "xvdj:vol-040a345567e8228f6:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdk"]
  id = "vol-036210f231728cc61"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdk"]
  id = "xvdk:vol-036210f231728cc61:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdl"]
  id = "vol-04866216a4c04fc08"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdl"]
  id = "xvdl:vol-04866216a4c04fc08:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdm"]
  id = "vol-0a2818d6252e83ec1"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdm"]
  id = "xvdm:vol-0a2818d6252e83ec1:i-030db90a2de02f56e"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdn"]
  id = "vol-03c0b2549c2596a73"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdn"]
  id = "xvdn:vol-03c0b2549c2596a73:i-030db90a2de02f56e"
}

# Import volumes + attachments TariffDB subnet B
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvde"]
  id = "vol-0c4c5c5c9965a4995"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvde"]
  id = "xvde:vol-0c4c5c5c9965a4995:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdf"]
  id = "vol-003f2a06c1d0fc633"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdf"]
  id = "xvdf:vol-003f2a06c1d0fc633:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdg"]
  id = "vol-01734340782caff24"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdg"]
  id = "xvdg:vol-01734340782caff24:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdh"]
  id = "vol-0858561bccd244619"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdh"]
  id = "xvdh:vol-0858561bccd244619:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdi"]
  id = "vol-008d101c2bd92a11b"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdi"]
  id = "xvdi:vol-008d101c2bd92a11b:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdj"]
  id = "vol-0f73727edcf8f5064"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdj"]
  id = "xvdj:vol-0f73727edcf8f5064:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdk"]
  id = "vol-06bde5b029f52f672"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdk"]
  id = "xvdk:vol-06bde5b029f52f672:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdl"]
  id = "vol-0991c1cbbc54f5fde"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdl"]
  id = "xvdl:vol-0991c1cbbc54f5fde:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdm"]
  id = "vol-0e8388d6835a171f9"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdm"]
  id = "xvdm:vol-0e8388d6835a171f9:i-0939a0ee8fb520bc9"
}
import {
  to = aws_ebs_volume.tariffdb_storage["subnet_a-xvdn"]
  id = "vol-05f9b59545f6f6609"
}

import {
  to = aws_volume_attachment.tariffdb_attachment["subnet_a-xvdn"]
  id = "xvdn:vol-05f9b59545f6f6609:i-0939a0ee8fb520bc9"
}