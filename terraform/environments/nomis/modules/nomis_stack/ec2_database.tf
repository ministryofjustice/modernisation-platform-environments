#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "database_server" {
  description = "Stack specific security group rules for database instance"
  name        = "database-${var.stack_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  dynamic "ingress" { # extra ingress rules that might be specified
    for_each = var.database_extra_ingress_rules
    iterator = rule
    content {
      description     = rule.value.description
      from_port       = rule.value.from_port
      to_port         = rule.value.to_port
      protocol        = rule.value.protocol
      security_groups = rule.value.security_groups
      cidr_blocks     = rule.value.cidr_blocks
    }
  }

  ingress {
    description = "DB access from weblogic (private subnet)"
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "TCP"
    cidr_blocks = ["${aws_instance.weblogic_server.private_ip}/32"]
  }

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}"
    }
  )
}

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------
data "aws_ami" "database_image" {
  most_recent = true
  owners      = [var.database_ami_owner]

  filter {
    name   = "name"
    values = [var.database_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  database_root_device_size = one([for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.database_image.root_device_name])
}

resource "aws_instance" "database_server" {
  ami                         = data.aws_ami.database_image.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = var.instance_profile_id
  instance_type               = var.database_instance_type # tflint-ignore: aws_instance_invalid_type
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_az_a.id
  user_data                   = file("${path.module}/user_data/database_init.sh")
  vpc_security_group_ids = [
    var.database_common_security_group_id,
    aws_security_group.database_server.id
  ]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = lookup(var.database_drive_map, data.aws_ami.database_image.root_device_name, local.database_root_device_size)
    volume_type           = "gp3"
  }
  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.database_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.database_image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device, # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    var.tags,
    {
      Name       = "database-${var.stack_name}"
      component  = "data"
      os_type    = "Linux"
      os_version = "RHEL 7.9"
      always_on  = "false"
    }
  )
}

resource "aws_ebs_volume" "database_server_ami_volume" {
  for_each = { for bdm in data.aws_ami.database_image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.database_image.root_device_name }

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = each.value["ebs"]["iops"]
  snapshot_id       = each.value["ebs"]["snapshot_id"]
  size              = lookup(var.database_drive_map, each.value["device_name"], each.value["ebs"]["volume_size"])
  type              = each.value["ebs"]["volume_type"]

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}-${each.value.device_name}"
    }
  )
}

resource "aws_volume_attachment" "database_server_ami_volume" {
  for_each = aws_ebs_volume.database_server_ami_volume

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database_server.id
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "database" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "database-${var.stack_name}.${var.application_name}.${var.business_unit}-${var.environment}.modernisation-platform.internal"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.database_server.private_ip]
}