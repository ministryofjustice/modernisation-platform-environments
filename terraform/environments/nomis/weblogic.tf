#------------------------------------------------------------------------------
# Networking and Security Groups
#------------------------------------------------------------------------------
data "aws_subnet" "private_az_a" {
  vpc_id = local.vpc_id
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

# Security Groups
resource "aws_security_group" "weblogic_server" {
  description = "Configure weblogic access - ingress should be only from Bastion"
  name        = "weblogic-server-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description     = "access from Windows Jumpserver (admin console)"
    from_port       = "7001"
    to_port         = "7001"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description     = "access from Windows Jumpserver"
    from_port       = "80"
    to_port         = "80"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description     = "access from Windows Jumpserver (forms/reports)"
    from_port       = "7777"
    to_port         = "7777"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id, aws_security_group.internal_elb.id]
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
    local.tags,
    {
      Name = "weblogic-server-${local.application_name}"
    }
  )
}

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------
data "aws_ami" "weblogic_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["weblogic-2022-01-12"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "weblogic_server" {
  #checkov:skip=CKV_AWS_135:skip "Ensure that EC2 is EBS optimized" as not supported by t2 instances.
  # t2 was chosen as t3 does not support RHEL 6.10. Review next time instance type is changed.
  instance_type               = "t2.medium"
  ami                         = data.aws_ami.weblogic_image.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_common_profile.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.weblogic_server.id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  user_data                   = file("./templates/weblogic-init.sh")
  # ebs_optimized          = true
  key_name = aws_key_pair.ec2-user.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted = true
  }

  tags = merge(
    local.tags,
    {
      Name       = "weblogic"
      component  = "application"
      os_type    = "Linux"
      os_version = "RHEL 6.10"
      always_on  = "false"
    }
  )
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------
resource "aws_route53_record" "weblogic" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "weblogic.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.internal"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.db_server.private_ip]
}

resource "aws_ebs_volume" "extra_disk" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 150

  tags = merge(
    local.tags,
    {
      Name = "weblogic-${local.application_name}-extra-disk"
    }
  )
}

resource "aws_volume_attachment" "extra_disk" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.extra_disk.id
  instance_id = aws_instance.weblogic_server.id
}
