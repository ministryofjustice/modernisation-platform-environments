locals {
  name   = "NPS"
  region = "eu-west-2"

}

################################################################################

resource "aws_kms_key" "this" {
  enable_key_rotation = true
  policy              = local.is-development ? data.aws_iam_policy_document.kms_policy[0].json : ""
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
  key_name   = "moj-keys"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCRaG+djcdPnJ0fvqUBdOhBqwvoXz7x7DxPeQ8SJ5Hg0thXDg8lUSRrUYdZjqFXo39sBvgLSGxjaCRbSFsyR3aFgsVsW/ZJ7+L6j9h2HUdpGj/0brdBlpHJkVI5y18PYET8r/bQRAh78jQcyxYkGc84sfw510vR3gZ3jbHdglY6vlhvhAWwuegSdISx4HjXFov2CJR09f4U6fp6Qrm3z0bOICShFEK9WGxdFZs9PaTxr9gzPbBfdaZtWN6dj7fuQXzytlNAd1UFWiL2sVjXyGxmNlnChlMBE+WjAO99yvnPNdrr3C8jzFoP8tYISGngp0Au2AtioAq7cvdjvhd8p9/1"
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
      vpc_security_group_ids = [aws_security_group.aws_domain_security_group.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-DC01-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-DC01"
        Role = "Domain Controller" }
      )
    }
    COR-A-DC02 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_b.id
      vpc_security_group_ids = [aws_security_group.aws_domain_security_group.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-DC02-root-block"
            Role = "Domain Controller" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-DC02"
        Role = "Domain Controller" }
      )
    }
    COR-A-CTX01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_citrix_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-CTX01-root-block" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-CTX01-ebs-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-CTX01"
        Role = "Citrix Infrastructure" }
      )
    }
    COR-A-CTX02 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_citrix_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-CTX02-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-CTX02"
        Role = "Citrix Session Host" }
      )
    }
    COR-A-CTX03 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_citrix_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 100
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-CTX03-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-CTX03"
        Role = "Citrix Session Host" }
      )
    }
    COR-A-PXY01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_proxy_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 70
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-PXY01-root-block" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 500
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-PXY01-ebs-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-PXY01"
        Role = "Proxy Services" }
      )
    }
    COR-A-TST01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_equip_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-TST01-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-TST01"
        Role = "Test Server" }
      )
    }
  }
}

module "win2016_multiple" {
  #  source = "git::https://github.com/rvadisala/ec2-instance?ref=tags/v2.0"
  source = "./ec2-instance-module"


  for_each = local.win2016_instances

  name                   = "${local.name}-${each.key}"
  ami                    = "ami-0eb1bbd88dd77f1b7"
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name
  user_data              = data.template_file.windows-userdata.rendered
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name

  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = merge(each.value.tags, local.tags,
    { Environment = "development"
    terraform_managed = "true" },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling }
  )
}


################################################################################

data "aws_ami" "windows_2016_std_SQL17_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-SQL_2017_Standard*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "SOC" {
  lifecycle { ignore_changes = [ebs_block_device] }
  ami = "ami-0781096210795e2d3"

  instance_type          = "t3a.xlarge"
  availability_zone      = "${local.region}a"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.aws_proxy_security_group.id, aws_security_group.all_internal_groups.id, aws_security_group.aws_soc_security_group.id]
  monitoring             = true
  ebs_optimized          = true
  user_data              = data.template_file.windows-userdata.rendered
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name
  key_name               = aws_key_pair.windowskey.key_name

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 70
    kms_key_id  = aws_kms_key.this.arn
    tags = merge(local.tags,
      { Name = "NPS-COR-A-SOC01-root-block" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    kms_key_id  = aws_kms_key.this.arn
    tags = merge(local.tags,
      { Name = "NPS-COR-A-SOC01-ebs-block1" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_type = "gp3"
    volume_size = 300
    encrypted   = true
    kms_key_id  = aws_kms_key.this.arn
    tags = merge(local.tags,
      { Name = "NPS-COR-A-SOC01-ebs-block2" }
    )
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = "NPS-COR-A-SOC01"
    ROLE = "Security Operation Center Gateway" },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling }
  )

}

################################################################################

data "aws_ami" "windows_2019_std_SQL17_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-SQL_2017_Standard*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  win2019_SQL_instances = {
    COR-A-SF02 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_spotfire_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 70
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-SF02-root-block" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 125
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-SF02-ebs-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-SF02"
        Role = "Spotfire Database Server" }
      )
    }
  }
}

module "win2019_SQL_multiple" {
  source = "./ec2-instance-module"


  for_each = local.win2019_SQL_instances

  name                   = "${local.name}-${each.key}"
  ami                    = "ami-0d6ed9f188054719d"
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name
  user_data              = data.template_file.windows-userdata.rendered
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name


  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = merge(each.value.tags, local.tags, {
    Environment = "development"
    terraform_managed = "true" },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling }
  )

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
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_equip_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 90
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP01-root-block" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP01-ebs-block-1" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdg"
          volume_type = "gp3"
          volume_size = 200
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP01-ebs-block-2" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdh"
          volume_type = "gp3"
          volume_size = 1000
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP01-ebs-block-3" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-EQP01"
        Role = "Nimbus Application Services" }
      )
    }
    COR-A-EQP02 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_equip_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 80
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP02-root-block" }
          )
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 100
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP02-ebs-block-1" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-EQP02"
        Role = "Nimbus Application Services" }
      )
    }
    COR-A-EQP03 = {
      instance_type          = "t3a.xlarge"
      subnet_id              = data.aws_subnet.private_subnets_c.id
      vpc_security_group_ids = [aws_security_group.aws_equip_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-EQP03-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-EQP03"
        Role = "Nimbus Application Services" }
      )
    }
    COR-A-SF01 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_spotfire_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-SF01-root-block" }
          )
        }
      ]
      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-SF01"
        Role = "Spot Fire Server" }
      )
    }
    COR-A-SF03 = {
      instance_type          = "t3a.large"
      subnet_id              = data.aws_subnet.private_subnets_a.id
      vpc_security_group_ids = [aws_security_group.aws_spotfire_security_group.id, aws_security_group.all_internal_groups.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 60
          kms_key_id  = aws_kms_key.this.arn
          tags = merge(local.tags,
            { Name = "${local.name}-COR-A-SF03-root-block" }
          )
        }
      ]

      tags = merge(local.tags,
        { Name = "${local.name}-COR-A-SF03"
        Role = "Spot Fire WebPlayer Server" }
      )
    }
  }
}


module "win2012_STD_multiple" {
  source = "./ec2-instance-module"


  for_each = local.win2012_STD_instances

  name                   = "${local.name}-${each.key}"
  ami                    = "ami-04208d5dbf1d2dd44"
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  subnet_id              = each.value.subnet_id
  monitoring             = true
  ebs_optimized          = true
  key_name               = aws_key_pair.windowskey.key_name
  user_data              = data.template_file.windows-userdata.rendered
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name

  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = merge(each.value.tags, local.tags, {
    Environment = "development"
    terraform_managed = "true" },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling }
  )
}
