# HMPPS Intranet snapshots

# This data should be retained until after the Covid Enquiry
# Use the AMIs to create a new instance of each server from the snapshots
# To access the file system connect via a bastion using the root user and the password stored in the secret
# To access the database dump create a volume from the snapshot and attach to any EC2 instance
# More info on accessing the data here https://docs.google.com/document/d/1Ky02UTaHYdmvMP-w89iDHjEmRDc-1OAW79OUPwvM-VU/

# KMS key for snapshot encryption
resource "aws_kms_key" "hmpps_intranet" {
  description         = "KMS key to encrypt the HMPPS Intranet EBS volume"
  enable_key_rotation = true
}

resource "aws_kms_alias" "hmpps_intranet" {
  name          = "alias/hmpps-intranet"
  target_key_id = aws_kms_key.hmpps_intranet.key_id
}

# OS root password
resource "aws_secretsmanager_secret" "hmpps_intranet_root_password" {
  # checkov:skip=CKV_AWS_149 "standard encryption key is sufficient"
  name = "hmpps-intranet-root-password"
  tags = local.tags
}

# Snapshot containing postgres database dump
resource "aws_ebs_snapshot" "hmpps_db_dump" {
  volume_id   = "vol-066ff696e64e73fce"
  description = "HMPPS Intranet - Volume with Postgres dump from SIP-PROD-WEB-001"

  tags = merge(
    local.tags,
    {
      Name  = "HMPPS Intranet Postgres dump",
      owner = "HMPPS Intranet"
    },
  )
}

# HMPPS Intranet - SIP-PROD-FB-001

resource "aws_ami" "hmpps_intranet_sip_prod_fb_001" {
  name                = "HMPPS Intranet - SIP-PROD-FB-001"
  description         = "HMPPS Intranet - SIP-PROD-FB-001 - /dev/sda1 - CACI - snap-09cc4d15745b8399b - CACI with MoJ KMS - snap-0334405ba293ff28a"
  virtualization_type = "hvm"
  ena_support         = true
  root_device_name    = "/dev/sda1"
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sda1"
    snapshot_id           = aws_ebs_snapshot.sip_prod_fb_001_sda1.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdf"
    snapshot_id           = aws_ebs_snapshot.sip_prod_fb_001_sdf.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdg"
    snapshot_id           = aws_ebs_snapshot.sip_prod_fb_001_sdg.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdh"
    snapshot_id           = aws_ebs_snapshot.sip_prod_fb_001_sdh.id
    volume_type           = "gp2"
  }
  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-FB-001",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_fb_001_sdg" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-FB-001 - /dev/sdg - CACI - snap-0bf60932f6c4e8538 - CACI with MoJ KMS - snap-0c6d211a0ee41e4ba"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-FB-001-sdg",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_fb_001_sdh" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-FB-001 - /dev/sdh - CACI - snap-0d03ca63a99506aac - CACI with MoJ KMS - snap-0150b0fdaec4a2cfa"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-FB-001-sdh",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_fb_001_sdf" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-FB-001 - /dev/sdf - CACI - snap-0412862f3adf9550e - CACI with MoJ KMS - snap-0d560579f0d09773f"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-FB-001-sdf",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_fb_001_sda1" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-FB-001 - /dev/sda1 - CACI - snap-09cc4d15745b8399b - CACI with MoJ KMS - snap-0334405ba293ff28a"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-FB-001-sda1",
      owner = "HMPPS Intranet"
    }
  )
}

# HMPPS Intranet - SIP-PROD-WEB-001
# Note: instance size to run database should be m4.2xlarge
resource "aws_ami" "hmpps_intranet_sip_prod_web_001" {
  name                = "HMPPS Intranet - SIP-PROD-WEB-001"
  description         = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sda1 - CACI - snap-064d34700e9e57159 - CACI with MoJ KMS - snap-0ac41cccad8708c82"
  virtualization_type = "hvm"
  ena_support         = true
  root_device_name    = "/dev/sda1"
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sda1"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sda1.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdg"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdg.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdk"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdk.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdi"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdi.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdj"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdj.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdh"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdh.id
    volume_type           = "gp2"
  }
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdf"
    snapshot_id           = aws_ebs_snapshot.sip_prod_web_001_sdf.id
    volume_type           = "gp2"
  }

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdg" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdg - CACI - snap-049a73e3b2ce52a77 - CACI with MoJ KMS - snap-0ff2cfb30c7f836ed"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdg",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdk" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdk - CACI - snap-04f42995cabbf0ae9 - CACI with MoJ KMS - snap-0387baa36efd264d4"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdk",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sda1" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sda1 - CACI - snap-064d34700e9e57159 - CACI with MoJ KMS - snap-0ac41cccad8708c82"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sda1",
      owner = "HMPPS Intranet"
    }
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdi" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdi - CACI - snap-09e742299d365bf88 - CACI with MoJ KMS - snap-0afb85e023b7f05c4"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdi",
      owner = "HMPPS Intranet"
    }
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdj" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdj - CACI - snap-01993f31e1b424c84 - CACI with MoJ KMS - snap-04487efb973ab0050"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdj",
      owner = "HMPPS Intranet"
    }
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdh" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdh - CACI - snap-0bcd723c184f27c67 - CACI with MoJ KMS - snap-097c047235d459693"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdh",
      owner = "HMPPS Intranet"
    },
  )
}

resource "aws_ebs_snapshot" "sip_prod_web_001_sdf" {
  volume_id   = "vol-ffffffff"
  description = "HMPPS Intranet - SIP-PROD-WEB-001 - /dev/sdf - CACI - snap-00d166b08063aeded - CACI with MoJ KMS - snap-0c49972b7a7dafda4"

  tags = merge(
    local.tags,
    {
      Name  = "SIP-PROD-WEB-001-sdf",
      owner = "HMPPS Intranet"
    },
  )
}
