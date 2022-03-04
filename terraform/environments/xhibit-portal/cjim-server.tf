
# Security Groups
resource "aws_security_group" "cjim-server" {
  description = "Bastion traffic"
  name        = "cjim-server-${local.application_name}"
  vpc_id      = local.vpc_id
}


resource "aws_security_group_rule" "cjim-outbound-all" {
  depends_on        = [aws_security_group.cjim-server]
  security_group_id = aws_security_group.cjim-server.id
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "cjim-inbound-all" {
  depends_on        = [aws_security_group.cjim-server]
  security_group_id = aws_security_group.cjim-server.id
  type              = "ingress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# resource "aws_security_group_rule" "cjim-inbound-bastion" {
#   depends_on        = [aws_security_group.cjim-server]
#   security_group_id = aws_security_group.cjim-server.id
#   type              = "ingress"
#   description       = "allow bastion"
#   from_port         = 0
#   to_port           = 3389
#   protocol          = "TCP"
#   cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
# }

# resource "aws_security_group_rule" "cjip-inbound-web" {
#   depends_on               = [aws_security_group.cjim-server]
#   security_group_id        = aws_security_group.cjim-server.id
#   type                     = "ingress"
#   description              = "allow web from cjip"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.cjip-server.id
# }

// added for the msdtc thing
resource "aws_security_group_rule" "cjim-portal-inbound-all" {
  depends_on               = [aws_security_group.cjim-server]
  security_group_id        = aws_security_group.cjim-server.id
  type                     = "ingress"
  description              = "allow all from portal"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal-server.id
}

resource "aws_instance" "cjim-server" {
  depends_on                  = [aws_security_group.cjim-server]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].suprig04-ami
  vpc_security_group_ids      = [aws_security_group.cjim-server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
    tags = {
      Name = "root-block-device-cjim-${local.application_name}"
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
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "cjim-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "cjim-disk1" {
  depends_on        = [aws_instance.cjim-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig04-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "cjim-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "cjim-disk1" {
  depends_on   = [aws_instance.cjim-server]
  device_name  = "xvdk"
  force_detach = true
  volume_id    = aws_ebs_volume.cjim-disk1.id
  instance_id  = aws_instance.cjim-server.id
}
