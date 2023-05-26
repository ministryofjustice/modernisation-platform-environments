



resource "aws_security_group" "portalsg" {
  name        = "${local.application_name}-${local.environment}-secgroup"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = 1
    protocol    = "ICMP"
    cidr_blocks = [local.firstohs-cidr]

  }
  ingress {
    description = "OHS Inbound from Local account VPC"
    from_port   = 7777
    to_port     = 7777
    protocol    = "TCP"
    cidr_blocks = [local.firstohs-cidr]

  }
  ingress {
    description = "ONS Port"
    from_port   = 6200
    to_port     = 6200
    protocol    = "TCP"
    cidr_blocks = [local.firstohs-cidr]

  }

  # ingress {
  #   description = "SSH access from bastion"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.secondohs-cidr]

  # }
  # ingress {
  #   description = "SSH access from VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.firstohs-cidr]

  # }
   ingress {
    description = "OHS Inbound from Shared Svs VPC"
    from_port   = 7777
    to_port     = 7777
    protocol    = "TCP"
    cidr_blocks = [local.secondohs-cidr]

  }
  #   ingress {
  #   description = "SSH access from prod bastion"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.prd-cidr]

  # }
  #   ingress {
  #   description = "OHS Inbound from Prod Shared Svs VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "7777"
  #   cidr_blocks = [local.prd-cidr]

  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-portal" }
  )
}



resource "aws_instance" "ohs1" {
  ami                         = local.ami-id
  instance_type               = local.application_data.accounts[local.environment].ohs_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.portalsg.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id

  # root_block_device {
  #   delete_on_termination      = false
  #   encrypted                  = true 
  #   volume_size                = 60
  #   volume_type                = "gp2"
  #   tags = merge(
  #     local.tags,
  #     { "Name" = "${local.application_name}-root-volume" },
  #   )
  # }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} OHS Instance 1" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}


resource "aws_instance" "ohs2" {
  count = local.environment == "production" ? 1 : 0
  ami                            = local.ami-id
  instance_type                  = local.application_data.accounts[local.environment].ohs_instance_type
  vpc_security_group_ids         = [aws_security_group.portalsg.id]
  subnet_id                      = data.aws_subnet.data_subnets_b.id
  iam_instance_profile           = aws_iam_instance_profile.portal.id

  #   # root_block_device {
  #   # delete_on_termination     = false
  #   # encrypted                 = true 
  #   # volume_size               = 60
  #   # volume_type               = "gp2"
  #   # tags = merge(
  #   #   local.tags,
  #   #   { "Name" = "${local.application_name}-root-volume" },
  #   # )
  # }


  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} OHS Instance 2" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}


resource "aws_ebs_volume" "ohsvolume1" {
  availability_zone = "eu-west-2a"
  size              = "30"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ohssnapshot1

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OHSVolume1" },
  )
}

resource "aws_volume_attachment" "ohs_EC2ServerVolume01" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.ohsvolume1.id
  instance_id = aws_instance.ohs1.id
}

resource "aws_ebs_volume" "ohsvolume2" {
  availability_zone = "eu-west-2a"
  size              = "30"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ohssnapshot2

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-OHSVolume2" },
  )
}

resource "aws_volume_attachment" "ohs_EC2ServerVolume02" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.ohsvolume2.id
  instance_id = aws_instance.ohs1.id
}