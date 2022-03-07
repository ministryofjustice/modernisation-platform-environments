data "aws_caller_identity" "current" {}

data "aws_ami" "database" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ec2_instance_type" "database" {
  instance_type = var.instance_type
}

locals {
  region = substr(var.availability_zone,0,length(var.availability_zone)-1)


  oracle_app_disks = [ # match structure of AMI block device mappings
    "/dev/sdb",
    "/dev/sdc"
  ]
  asm_data_disks = [ # match structure of AMI block device mappings
    "/dev/sde", # DATA01
    "/dev/sdf", # DATA02
    "/dev/sdg", # DATA03
    "/dev/sdh", # DATA04
    "/dev/sdi", # DATA05
    ]
  asm_flash_disks = [ # match structure of AMI block device mappings
    "/dev/sdj", # FLASH01
    "/dev/sdk"  # FLASH02
    ]
  swap_disk = "/dev/sds" # match structure of AMI block device mappings

  asm_data_disk_size = floor(var.asm_data_capacity / length(local.asm_data_disks))
  asm_flash_disk_size = floor(var.asm_flash_capacity / length(local.asm_flash_disks))
  block_device_map = { for bdm in data.aws_ami.database.block_device_mappings : bdm.device_name => bdm }
  root_device_size = one([for bdm in data.aws_ami.database.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.database.root_device_name])

  # set swap space according to https://docs.oracle.com/cd/E11882_01/install.112/e47689/oraclerestart.htm#LADBI1214 (assuming we will never have instances < 2GB)
  # output from datasource is in MiB, we spec swap sapce in GiB
  swap_disk_size = data.aws_ec2_instance_type.database.memory_size >= 16384 ? 16 : (data.aws_ec2_instance_type.database.memory_size / 1024)

}