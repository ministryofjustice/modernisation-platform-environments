# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
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

  egress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "weblogic-server-${local.application_name}"
    }
  )
}

# EC2 instance

data "aws_ami" "weblogic_image" {
  most_recent = true
  owners      = ["self"] # 309956199498 Red Hat - this will be a custom image later "self" .

  filter {
    name   = "name"
    values = ["nomis_app-2021-09-20*"] # temp. fix this to prevent any more accidental replacements
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "weblogic_server" {
  instance_type               = "t2.medium"
  ami                         = data.aws_ami.weblogic_image.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_common_profile.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.weblogic_server.id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  user_data                   = file("./templates/cloudinit.cfg")
  # ebs_optimized          = true
  # key_name                  = aws_key_pair.ec2-user.key_name add this on next rebuild

  root_block_device {
    encrypted = true
  }

  tags = merge(
    local.tags,
    {
      Name = "weblogic"
    }
  )
}

resource "aws_ebs_volume" "extra_disk" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 50

  tags = merge(
    local.tags,
    {
      Name = "weblogic-${local.application_name}-extra-disk"
    }
  )
}

resource "aws_volume_attachment" "extra_disk" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.extra_disk.id
  instance_id = aws_instance.weblogic_server.id
}
