# data "amazon-ami" "this" {
#   filters = {
#     virtualization-type = "hvm"
#     name                = "${var.source_image_name}*"
#     root-device-type    = "ebs"   
#   }
#   owners      = [var.source_image_owner_id]
#   most_recent = true
#   region = var.region
# }

# data "amazon-ebs" "basic-example" {
#   subnet_filter {
#     filters = {
#           "tag:Class": "build"
#     }
#     most_free = true
#     random = false
#   }
# }

# data "sshkey" "akey" {
# }

# locals {
#   source_ami_id = data.amazon-ami.this.id
#   source_ami_name = data.amazon-ami.this.name
#   ami_name = "${var.app_name}-${local.source_ami_name}" # it doesn't like this as an AMI name for some reason
# }

source "amazon-ebs" "this" {
  # assume_role {
  #   role_arn = "arn:aws:iam::612659970365:role/MemberInfrastructureAccess"
  # }
  ami_name      = "${var.app_name}-${formatdate("YYYY-MM-DD'T'hh.mm.ssZ",timestamp())}" # this need to be something easily referenced in ec2 creation terraform, although could use data source for that and filter on owned amis, owners = ["self"]
  instance_type = var.instance_type
  region        = var.region
  vpc_id = "vpc-0bc6de192f48dbef9" # hmpps-test
  subnet_id = "subnet-0b8492e457b5a7297" # hmpps-test-nomis-private-eu-west-2a 
  source_ami = "ami-00a54967" #local.source_ami_id
  ssh_username = "ec2-user"
  # ssh_private_key_file = data.sshkey.akey.private_key_path
  # session_manager =
  skip_create_ami = var.skip_create_ami
  encrypt_boot = true
  tags = {
    # base_AMI = local.source_ami_name
    application = var.app_name
    owner = "digital-studio-operations-team@digital.justice.gov.uk"
    is_production = "false"
    business_unit = "HMPPS"
  }

  launch_block_device_mappings { 
    device_name = "/dev/sda1" # root volume
    encrypted = true
    delete_on_termination = true
    volume_size = 30
    volume_type = "gp2"
  }

  ami_block_device_mappings {
    device_name = "/dev/sdb"
    encrypted = true
    delete_on_termination = true
    volume_size = 256
    volume_type = "gp2" # determine existing sizes and type - is it still appropriate.  gp3 allows iops to be determined independently of size

  }
}


build {
  name    = "test-packer-rw"
  sources = ["source.amazon-ebs.this"]

  # post-processor "manifest" {
  #   custom_data = {
  #     base_image = local.source_ami_name
  #   }
  # }
}