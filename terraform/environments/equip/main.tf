locals {
  name   = "moj"
  region = "eu-west-2"

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

################################################################################


data "aws_availability_zones" "available" {}

locals {
  multiple_instances = {
    one = {
      instance_type     = "t2.micro"
      availability_zone = "${local.region}a"
      subnet_id         = data.aws_subnet.public_az_a.id
      security_groups   = [aws_security_group.aws_sec.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          throughput  = 200
          volume_size = 30
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "one-root-block"
          }
        },
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = 5
          throughput  = 200
          encrypted   = true
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "one-ebs-block"
          }
        }
      ]
    }
    two = {
      instance_type     = "t3.small"
      availability_zone = "${local.region}b"
      subnet_id         = data.aws_subnet.private_subnets_a
      #    vpc_security_group_ids = [aws_security_group.aws_sec.id]
      security_groups = [aws_security_group.aws_sec.id]
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp2"
          volume_size = 50
          kms_key_id  = aws_kms_key.this.arn
          tags = {
            Name = "two-root-block"
          }
        }
      ]
    }
  }
}

module "ec2_multiple" {
  source = "git::https://github.com/rvadisala/ec2-instance?ref=tags/v1.0"

  for_each = local.multiple_instances

  name              = "${local.name}-multi-${each.key}"
  ami               = data.aws_ami.windows_2016_ami.id
  instance_type     = each.value.instance_type
  availability_zone = each.value.availability_zone
  #  subnet_id              = each.value.subnet_id

  enable_volume_tags = false
  root_block_device  = lookup(each.value, "root_block_device", [])
  ebs_block_device   = lookup(each.value, "ebs_block_device", [])

  tags = {
    Owner             = "ROC"
    Environment       = "development"
    terraform_managed = "true"
  }

}

resource "aws_instance" "test" {
  ami = data.aws_ami.windows_2016_ami.id

  instance_type     = "t3.small"
  availability_zone = "${local.region}a"
  subnet_id         = data.aws_subnet.public_az_a.id
  security_groups   = [aws_security_group.aws_sec.id]
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
