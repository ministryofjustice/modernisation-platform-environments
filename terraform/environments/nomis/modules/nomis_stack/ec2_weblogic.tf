
#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

# The security group will be common across all weblogic instances.  Since they
# will be accessed from a single jumpserver.  Also it makes it easier to manage
# the loadbalancer egress rules if there is a single security group.

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
  # user_data                   = file("./templates/cloudinit.cfg")
  # ebs_optimized          = true
  key_name = var.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
    volume_type           = "gp3"
  }

  dynamic "ebs_block_device" {
    for_each = [for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.weblogic_image.root_device_name]
    iterator = device
    content {
      device_name           = device.value["device_name"]
      delete_on_termination = true
      encrypted             = true
      iops                  = device.value["ebs"]["iops"]
      snapshot_id           = device.value["ebs"]["snapshot_id"]
      volume_size           = lookup(var.weblogic_drive_map, device.value["device_name"], device.value["ebs"]["volume_size"])
      volume_type           = device.value["ebs"]["volume_type"]
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