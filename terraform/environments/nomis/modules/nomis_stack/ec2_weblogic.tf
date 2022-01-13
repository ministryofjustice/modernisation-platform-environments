
#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

# The security group will be common across all weblogic instances so it is
# defined outside of this module. (it is envisaged that they will be accessed
# from a single jumpserver.  Also it makes it easier to manage the loadbalancer
# egress rules if there is a single security group.)

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------

data "aws_ami" "weblogic_image" {
  most_recent = true
  owners      = [var.weblogic_ami_owner]

  filter {
    name   = "name"
    values = [var.weblogic_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  weblogic_root_device_size = one([for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.weblogic_image.root_device_name])
}

data "template_file" "weblogic_init" {
  template = "${file("${path.module}/user_data/weblogic_init.sh")}"
  vars = {
    DB_HOSTNAME       = var.DB_HOSTNAME
    DB_NAME           = var.DB_NAME
    DB_PORT           = var.DB_PORT
    # Sensitive values (obtained via user input on "terraform apply")
    DB_USERNAME       = var.DB_USERNAME
    DB_PASSWORD       = var.DB_PASSWORD
    WEBLOGIC_USERNAME = var.WEBLOGIC_USERNAME
    WEBLOGIC_PASSWORD = var.WEBLOGIC_PASSWORD
  }
}

resource "aws_instance" "weblogic_server" {
  #checkov:skip=CKV_AWS_135:skip "Ensure that EC2 is EBS optimized" as not supported by t2 instances.
  # t2 was chosen as t3 does not support RHEL 6.10. Review next time instance type is changed.
  instance_type               = var.weblogic_instance_type
  ami                         = data.aws_ami.weblogic_image.id
  associate_public_ip_address = false
  iam_instance_profile        = var.instance_profile_id
  monitoring                  = false
  vpc_security_group_ids      = [var.weblogic_common_security_group_id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  user_data                   = data.template_file.weblogic_init.rendered
  ebs_optimized          = true
  key_name = var.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = lookup(var.weblogic_drive_map, data.aws_ami.weblogic_image.root_device_name, local.weblogic_root_device_size)
    volume_type           = "gp3"
  }

  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.weblogic_image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name       = "weblogic-${var.stack_name}"
      component  = "application"
      os_type    = "Linux"
      os_version = "RHEL 6.10"
      always_on  = "false"
    }
  )
}

resource "aws_ebs_volume" "weblogic_ami_volume" {
  for_each = { for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.weblogic_image.root_device_name }

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = each.value["ebs"]["iops"]
  snapshot_id       = each.value["ebs"]["snapshot_id"]
  size              = lookup(var.weblogic_drive_map, each.value["device_name"], each.value["ebs"]["volume_size"])
  type              = each.value["ebs"]["volume_type"]

  tags = merge(
    var.tags,
    {
      Name = "weblogic-${var.stack_name}-${each.value.device_name}"
    }
  )
}

resource "aws_volume_attachment" "weblogic_ami_volume" {
  for_each = aws_ebs_volume.weblogic_ami_volume

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.weblogic_server.id
}
