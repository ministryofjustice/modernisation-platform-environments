#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "db_server" {
  description = "Configure Oracle database access"
  name        = "database-${var.stack_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description     = "DB access from weblogic (private subnet)"
    from_port       = "1521"
    to_port         = "1521"
    protocol        = "TCP"
    cidr_blocks = ["${aws_instance.weblogic_server.private_ip}/32"]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags_common,
    {
      Name = "database-${var.stack_name}"
    }
  )
}

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------
data "aws_ami" "db_image" {
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

resource "aws_instance" "db_server" {
  # tflint-ignore: aws_instance_invalid_type
  instance_type               = "r6i.xlarge"
  ami                         = data.aws_ami.db_image.id
  monitoring                  = true
  associate_public_ip_address = false
  iam_instance_profile        = var.instance_profile_id
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.data_az_a.id
  user_data                   = file("./user_data/database_init.sh")
  vpc_security_group_ids      = [aws_security_group.db_server.id]
  key_name                    = var.key_name
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
    for_each = [for bdm in data.aws_ami.db_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.db_image.root_device_name]
    iterator = device
    content {
      device_name = device.value["device_name"]
      iops        = device.value["ebs"]["iops"]
      snapshot_id = device.value["ebs"]["snapshot_id"]
      volume_size = lookup(var.database_drive_map, device.value["device_name"], device.value["ebs"]["volume_size"])
      volume_type = device.value["ebs"]["volume_type"]
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
    var.tags_common,
    {
      Name       = "database-${var.stack_name}"
      component  = "data"
      os_type    = "Linux"
      os_version = "RHEL 7.9"
      always_on  = "false"
    }
  )
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "database" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id / this
  name    = "database-${var.stack_name}.${var.application_name}.${var.business_unit}-${var.environment}.modernisation-platform.internal"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.db_server.private_ip]
}