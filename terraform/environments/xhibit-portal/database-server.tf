# Security Groups section
resource "aws_security_group" "database-server" {
  description = "Bastion traffic"
  name        = "database-server-${local.application_name}"
  vpc_id      = local.vpc_id
}


resource "aws_security_group_rule" "database-outbound-all" {
  depends_on        = [aws_security_group.database-server]
  security_group_id = aws_security_group.database-server.id
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "database-inbound-all" {
  depends_on               = [aws_security_group.database-server]
  security_group_id        = aws_security_group.database-server.id
  type                     = "ingress"
  description              = "allow all"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "TCP"
  cidr_blocks              = ["0.0.0.0/0"]
  ipv6_cidr_blocks         = ["::/0"]
}

# ----------------------------------------------------------

# resource "aws_security_group_rule" "cjim-inbound-bastion" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "ingress"
#   description              = "allow bastion"
#   from_port                = 3389
#   to_port                  = 3389
#   protocol                 = "TCP"
#   cidr_blocks              = ["${module.bastion_linux.bastion_private_ip}/32"]
# }

resource "aws_security_group_rule" "dc-to-sql-icmp" {
  depends_on               = [aws_security_group.database-server]
  security_group_id        = aws_security_group.database-server.id
  type                     = "ingress"
  description              = "allow dc to sql traffic"
  from_port                = 0
  to_port                  = 0
  protocol                 = "ICMP"
  source_security_group_id = aws_security_group.domain-controllers.id
}

# resource "aws_security_group_rule" "sql-to-dc-icmp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow dc to sql traffic"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "ICMP"
#   source_security_group_id = aws_security_group.domain-controllers.id
# }


# resource "aws_security_group_rule" "dc-to-sql-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "ingress"
#   description              = "allow dc to sql traffic"
#   from_port                = 1400
#   to_port                  = 1499
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.domain-controllers.id
# }

# resource "aws_security_group_rule" "sql-to-dc-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow sql to dc traffic"
#   from_port                = 1400
#   to_port                  = 1449
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.domain-controllers.id
# }

resource "aws_security_group_rule" "dc-to-sql-udp" {
  depends_on               = [aws_security_group.database-server]
  security_group_id        = aws_security_group.database-server.id
  type                     = "ingress"
  description              = "allow dc to sql traffic"
  from_port                = 1400
  to_port                  = 1499
  protocol                 = "UDP"
  source_security_group_id = aws_security_group.domain-controllers.id
}

resource "aws_security_group_rule" "dc-to-sql-udp2" {
  depends_on               = [aws_security_group.database-server]
  security_group_id        = aws_security_group.database-server.id
  type                     = "ingress"
  description              = "allow dc to sql traffic"
  from_port                = 123
  to_port                  = 123
  protocol                 = "UDP"
  source_security_group_id = aws_security_group.domain-controllers.id
}

# resource "aws_security_group_rule" "sql-to-dc-udp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow sql to dc traffic"
#   from_port                = 123
#   to_port                  = 123
#   protocol                 = "UDP"
#   source_security_group_id = aws_security_group.domain-controllers.id
# }

# resource "aws_security_group_rule" "sql-to-dc-udp2" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow sql to dc traffic"
#   from_port                = 1400
#   to_port                  = 1449
#   protocol                 = "UDP"
#   source_security_group_id = aws_security_group.domain-controllers.id
# }

resource "aws_security_group_rule" "app-to-sql-icmp" {
  depends_on               = [aws_security_group.database-server]
  security_group_id        = aws_security_group.database-server.id
  type                     = "ingress"
  description              = "allow app to sql traffic"
  from_port                = 0
  to_port                  = 0
  protocol                 = "ICMP"
  source_security_group_id = aws_security_group.app-server.id
}

# resource "aws_security_group_rule" "app-to-sql-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "ingress"
#   description              = "allow app to sql traffic"
#   from_port                = 1000
#   to_port                  = 1499
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "app-to-sql-tcp2" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "ingress"
#   description              = "allow app to sql traffic"
#   from_port                = 2000
#   to_port                  = 2499
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "sql-to-app-icmp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "ICMP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "sql-to-app-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 1000
#   to_port                  = 1200
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "sql-to-cjim-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 2000
#   to_port                  = 2400
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.cjim-server.id
# }

# resource "aws_security_group_rule" "sql-to-app-tcp2" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 1400
#   to_port                  = 1449
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "sql-to-app-tcp3" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 2000
#   to_port                  = 2400
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.app-server.id
# }

# resource "aws_security_group_rule" "sql-out-udp" {
#   depends_on        = [aws_security_group.database-server]
#   security_group_id = aws_security_group.database-server.id
#   type              = "egress"
#   description       = "allow app to sql traffic"
#   from_port         = 1400
#   to_port           = 1449
#   protocol          = "UDP"
#   cidr_blocks       = ["10.33.0.0/16"]
# }

# resource "aws_security_group_rule" "sql-out-tcp" {
#   depends_on               = [aws_security_group.database-server]
#   security_group_id        = aws_security_group.database-server.id
#   type                     = "egress"
#   description              = "allow app to sql traffic"
#   from_port                = 1000
#   to_port                  = 1200
#   protocol                 = "TCP"
#   cidr_blocks              = ["192.168.0.0/16"]
# }

# ----------------------------------------------------------

resource "aws_instance" "database-server" {
  depends_on                  = [aws_security_group.database-server]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].suprig01-ami
  vpc_security_group_ids      = [aws_security_group.database-server.id]
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
    encrypted   = true
    volume_size = 64
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "database-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "database-disk1" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk1" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdl"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk1.id
  instance_id  = aws_instance.database-server.id
}




resource "aws_ebs_volume" "database-disk2" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-2-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk2-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk2" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdm"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk2.id
  instance_id  = aws_instance.database-server.id
}


resource "aws_ebs_volume" "database-disk3" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-3-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk3-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk3" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdn"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk3.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk4" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-4-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk4-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk4" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdo"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk4.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk5" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-5-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk5-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk5" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdy"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk5.id
  instance_id  = aws_instance.database-server.id
}


resource "aws_ebs_volume" "database-disk6" {
  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  #snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-6-snapshot

  size = 300

  tags = merge(
    local.tags,
    {
      Name = "database-disk6-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk6" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdf"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk6.id
  instance_id  = aws_instance.database-server.id
}
