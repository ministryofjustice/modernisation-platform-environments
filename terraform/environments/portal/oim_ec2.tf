



resource "aws_security_group" "oim_instance" {
  name        = "${local.application_name}-${local.environment}-oim-security-group"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id

ingress {
    description = "Nodemanager port"
    from_port   = 5556
    to_port     = 5556
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  
ingress {
    description = "OIM Admin Console from Shared Svs"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.second-cidr]

  }

ingress {
    description = "OIM Admin Console"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = 1
    protocol    = "ICMP"
    cidr_blocks = [local.first-cidr]

  }
  
  ingress {
    description = "OIM Inbound on 14000"
    from_port   = 14000
    to_port     = 14000
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Oracle BI Port"
    from_port   = 9704
    to_port     = 9704
    protocol    = "TCP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "Allow ping response"
    from_port   = 8
    to_port     = 1
    protocol    = "ICMP"
    cidr_blocks = [local.first-cidr]

  }

  ingress {
    description = "OIM Admin Console from Shared Svs"
    from_port   = 7101
    to_port     = 7101
    protocol    = "TCP"
    cidr_blocks = [local.third-cidr]

  }

  ingress {
    description = "SSH access from prod bastions"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [local.third-cidr]

  }

 
  # ingress {
  #   description = "SSH access from VPC"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.first-cidr]

  # }
 
  #   ingress {
  #   description = "SSH access from prod bastion"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = [local.prd-cidr]

  # }
  #   ingress {
  #   description = "oim Inbound from Prod Shared Svs VPC"
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


# TODO Depending on outcome of how EBS/EFS is used, this resource may depend on aws_instance.oam_instance_1

resource "aws_instance" "oim1" {
  ami                         = local.oim_ami-id
  instance_type               = local.application_data.accounts[local.environment].oim_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.oim_instance.id]
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
    { "Name" = "${local.application_name} OIM Instance 1" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}


resource "aws_instance" "oim2" {
  count = local.environment == "production" ? 1 : 0
  ami                            = local.oim_ami-id
  instance_type                  = local.application_data.accounts[local.environment].oim_instance_type
  vpc_security_group_ids         = [aws_security_group.oim_instance.id]
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
    { "Name" = "${local.application_name} OIM Instance 2" },
    { "snapshot-with-daily-35-day-retention" = "yes" }    # TODO the Backup rule needs setting up first
  )
}




