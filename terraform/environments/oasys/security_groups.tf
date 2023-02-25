# wondered about creating a security group module, but i don't think it'd be much simpler 
# since we'd need to define the in/egresses. Unless maybe we add default entries.

resource "aws_security_group" "webserver" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  description = "Common security group for webserver instances"
  name        = "webserver"
  vpc_id      = data.aws_vpc.shared.id

  # ingress {
  #   description     = "SSH from Bastion"
  #   from_port       = "22"
  #   to_port         = "22"
  #   protocol        = "TCP"
  #   security_groups = [module.bastion_linux.bastion_security_group]
  # }

  # ingress {
  #   description = "access from Cloud Platform Prometheus server"
  #   from_port   = "9100"
  #   to_port     = "9100"
  #   protocol    = "TCP"
  #   cidr_blocks = [local.cidrs.cloud_platform]
  # }

  # ingress {
  #   description = "access from Cloud Platform Prometheus script exporter collector"
  #   from_port   = "9172"
  #   to_port     = "9172"
  #   protocol    = "TCP"
  #   cidr_blocks = [local.cidrs.cloud_platform]
  # }

  # egress {
  #   description = "allow all"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   #tfsec:ignore:aws-vpc-no-public-egress-sgr
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = merge(
    local.tags,
    {
      Name = "webserver"
    }
  )
}

resource "aws_security_group_rule" "webserver_linux_egress_1" {
  security_group_id = aws_security_group.webserver.id

  description = "Allow all egress"
  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "TCP"
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "oasys" {
  name        = "${local.application_name}-${local.environment}-database-security-group"
  description = "Security group for ${local.application_name} ${local.environment} database"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database-security-group", local.application_name, local.environment)) }
  )
  ingress {
    description = "Allow access from live and test environments"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidrs.noms_live, data.aws_vpc.shared.cidr_block, local.cidrs.noms_test]
  }
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "data" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = "data"
  description = "Security group for data subnet"
  vpc_id      = module.environment.vpc.id

  ingress {
    description = "Allow all ingress to self"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  ingress {
    description = "Allow ssh ingress"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = local.security_group_cidrs.ssh
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "Allow prometheus node exporter ingress"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "Allow prometheus script exporter ingress"
    from_port   = "9172"
    to_port     = "9172"
    protocol    = "TCP"
    cidr_blocks = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "Allow oracle database 1521 ingress"
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "TCP"
    cidr_blocks = local.security_group_cidrs.oracle_db
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "Allow oem agent ingress"
    from_port   = "3872"
    to_port     = "3872"
    protocol    = "TCP"
    cidr_blocks = local.security_group_cidrs.oracle_oem_agent
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  egress {
    description     = "Allow all egress"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }

  tags = merge(local.tags, {
    Name = "data"
  })
}

resource "aws_security_group" "public" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource"
  name        = "public"
  description = "Security group for public subnet"
  vpc_id      = module.environment.vpc.id

  ingress {
    description = "Allow all ingress to self"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  ingress {
    description = "Allow ssh ingress"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = local.security_group_cidrs.ssh
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "Allow https ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
    cidr_blocks = local.security_group_cidrs.https
  }

  ingress {
    description = "Allow http7001 ingress"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
    cidr_blocks = local.security_group_cidrs.http7xxx
  }

  ingress {
    description = "Allow http7777 ingress"
    from_port   = 7777
    to_port     = 7777
    protocol    = "tcp"
    security_groups = [
      module.bastion_linux.bastion_security_group

    ]
    cidr_blocks = local.security_group_cidrs.http7xxx
  }

  egress {
    description     = "Allow all egress"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }

  tags = merge(local.tags, {
    Name = "public"
  })
}