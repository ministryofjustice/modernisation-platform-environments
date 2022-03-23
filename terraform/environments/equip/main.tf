locals {
  name   = "NPS"
  region = "eu-west-2"

}

################################################################################

data "aws_subnet" "data_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "data_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "data_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}c"
  }
}

################################################################################

resource "aws_kms_key" "this" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "this" {
  name          = "alias/moj-kms-keys"
  target_key_id = aws_kms_key.this.id
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "windowskey" {
  key_name   = "moj-win-key"
  public_key = tls_private_key.key.public_key_openssh
}

################################################################################

data "aws_ami" "windows_2016_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  win2016_instances = {
    COR-A-DC01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-DC01-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-DC01"
        Role = "Domain Controller"
      }
    }
    COR-A-DC02 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_b.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-DC02-root-block"
            Role = "Domain Controller"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-DC02"
        Role = "Domain Controller"
      }
    }
    COR-A-CTX01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      #      security_groups = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-CTX01-root-block"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-CTX01-ebs-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-CTX01"
        Role = "Citrix Infrastructure"
      }
    }
    COR-A-CTX02 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-CTX02-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-CTX02"
        Role = "Citrix Session Host"
      }
    }
    COR-A-CTX03 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.data_subnets_b.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-CTX03-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-CTX03"
        Role = "Citrix Session Host"
      }
    }
    COR-A-PXY01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 70
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-PXY01-root-block"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 500
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-PXY01-ebs-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-PXY01"
        Role = "Proxy Services"
      }
    }
    COR-A-TST01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-TST01-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-TST01"
        Role = "Test Server"
      }
    }
  }
}

module "win2016_multiple" {
  source = "git::https://github.com/rvadisala/ec2-instance?ref=tags/v1.0"


  for_each = local.win2016_instances

  name                   = "${local.name}-${each.key}"
  ami                    = data.aws_ami.windows_2016_ami.id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name


  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = {
    Environment       = "development"
    terraform_managed = "true"
  }
}


################################################################################

resource "aws_instance" "test" {
  ami = data.aws_ami.windows_2016_ami.id

  instance_type     = "t3.small"
  availability_zone = "${local.region}a"
  subnet_id         = data.aws_subnet.public_az_a.id
  security_groups   = [aws_security_group.ec2_security_dc.id, aws_security_group.ec2_security_citrix.id, aws_security_group.ec2_security_sf.id, aws_security_group.ec2_security_rdp.id, aws_security_group.ec2_security_adc.id, aws_security_group.ec2_security_samba.id]
  monitoring        = true
  ebs_optimized     = true
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    throughput  = 200
    volume_size = 30
    kms_key_id  = aws_kms_key.this.arn
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}


################################################################################

data "aws_ami" "windows_2012_std_SQL16_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-SQL_2016_SP3_Standard*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  win2012_SQL_instances = {
    COR-A-SF02 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 70
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-SF02-root-block"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 125
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-SF02-ebs-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-SF02"
        Role = "Spotfire Database Server"
      }
    }
  }
}

module "win2012_SQL_multiple" {
  source = "git::https://github.com/rvadisala/ec2-instance?ref=tags/v1.0"


  for_each = local.win2012_SQL_instances

  name                   = "${local.name}-${each.key}"
  ami                    = data.aws_ami.windows_2012_std_SQL16_ami.id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name


  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = {
    Environment       = "development"
    terraform_managed = "true"
  }
}


################################################################################

data "aws_ami" "windows_2012_std_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


locals {
  win2012_STD_instances = {
    COR-A-EQP01 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 90
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP01-root-block"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP01-ebs-block-1"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdg"
          volume_type = "gp3"
          volume_size = 400
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP01-ebs-block-2"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-EQP01"
        Role = "Nimbus Application Services"
      }
    }
    COR-A-EQP02 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.data_subnets_b.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 80
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP02-root-block"
          }
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP02-ebs-block-1"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-EQP02"
        Role = "Nimbus Application Services"
      }
    }
    COR-A-EQP03 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.data_subnets_c.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-EQP03-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-EQP03"
        Role = "Nimbus Application Services"
      }
    }
    COR-A-SF01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-SF01-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-SF01"
        Role = "Spot Fire Server"
      }
    }
    COR-A-SF03 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.data_subnets_a.id
      vpc_security_group_ids = [aws_security_group.ec2_security_dc.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "${local.name}-COR-A-SF03-root-block"
          }
        }
      ]
      tags = {
        Name = "${local.name}-COR-A-SF03"
        Role = "Spot Fire WebPlayer Server"
      }
    }
  }
}


module "win2012_STD_multiple" {
  source = "git::https://github.com/rvadisala/ec2-instance?ref=tags/v1.0"


  for_each = local.win2012_STD_instances

  name                   = "${local.name}-${each.key}"
  ami                    = data.aws_ami.windows_2012_std_ami.id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name


  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = {
    Environment       = "development"
    terraform_managed = "true"
  }
}
