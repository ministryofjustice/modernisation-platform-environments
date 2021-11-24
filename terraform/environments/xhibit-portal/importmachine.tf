

# Security Groups
resource "aws_security_group" "importmachine" {
  description = "Configure importmachine access - ingress should be only from Bastion"
  name        = "importmachine-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH from Bastion"
    from_port   = 0
    to_port     = "3389"
    protocol    = "TCP"
    cidr_blocks = ["${module.bastion_linux.bastion_private_ip}/32"]
  }

  egress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}


resource "aws_key_pair" "george" {
  key_name   = "george"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt2geFOwgsihu1oAG3RghCqercNTMv1QUgVnJvyllJGllRDbD5cfit5u3yKPB50W5IOgm9p+21epSRYSEL9TwkSNuveI1LK4CFDOurT5QiOSXL/0pFScwhSFbYud3IzbMJ8dEj/hyRm+gnqHbO86CJRBvSvL6j1Wn9S1rTPbfa0VmMehTsD2Wk181TlddIUBMnG+Dd4eeIoi5ivEzfM8jX4NJXzadXG/wTIrsx471tBF7g8TzCcYDMgTQw9oEdR3wugFjfuUDSK/SYXFTUpDOufZefpENcSW9SPDVfzCeM6ludNKxZFqVGAKwc7BFMygAucZjwVgiKxWBDVRcqTmtuM+ujoBh+d/o4RVGTs9V0MSE8YSIqk91U+/PRlL1nXBk0KaLqzB6/EdZZWxkxfhzv+iDrPnvqQd+ayzV0KcbzIP6iCxFn4YDM9jPWBDjIksKhi3TB4XyW446v6ttord0eB6glWFytA1LJ7Y7aiKaOnWa5oW7IbCZtE7PFxp+dmTk= george.cairns@MJ001152"
}

resource "aws_instance" "importmachine" {
  instance_type               = "t3.large"
  ami                         = "ami-0a0502ffd782e9b12"
  vpc_security_group_ids      = [aws_security_group.importmachine.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
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
      Name = "importmachine-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "disk_xvdf" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 6000

  tags = merge(
    local.tags,
    {
      Name = "importmachine-${local.application_name}-disk"
    }
  )
}

resource "aws_volume_attachment" "disk_xvdf" {
  device_name = "xvdf"
  volume_id   = aws_ebs_volume.disk_xvdf.id
  instance_id = aws_instance.importmachine.id
}



resource "aws_instance" "domaincheck" {
  instance_type               = "t3.medium"
  ami                         = "ami-0a0502ffd782e9b12"
  vpc_security_group_ids      = [aws_security_group.domaincheck.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
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
      Name = "dcheck-${local.application_name}"
    }
  )
}


# 

# Security Groups
resource "aws_security_group" "domain-check" {
  description = "Bastion traffic"
  name        = "domaincheck-${local.application_name}"
  vpc_id      = local.vpc_id
}


resource"aws_security_group_rule" "dcheck-outbound-all" {
    security_group_id  = aws_security_group.domain-check.id
    type            = "egress"
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "dcheck-inbound-bastion" {
    security_group_id  = aws_security_group.domain-check.id
    type            = "ingress"
    description      = "allow bastion"
    from_port        = 0
    to_port          = 3389
    protocol         = "TCP"
    cidr_blocks      = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "dcheck-to-dcs" {
    security_group_id        = aws_security_group.domain-check.id
    type                     = "egress"
    description              = "allow All"
    from_port                = 0
    to_port                  = 0
    protocol                 = -1
    source_security_group_id =  aws_security_group.domain-controllers.id



