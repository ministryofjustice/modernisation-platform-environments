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

  ingress = [
    local.security_group_common.self_ingress,
    local.security_group_common.ssh_ingress,
    local.security_group_common.prometheus_node_exporter_ingress,
    local.security_group_common.prometheus_script_exporter_ingress,

    {
      description = "Allow oracle database 1521 ingress"
      from_port   = "1521"
      to_port     = "1521"
      protocol    = "TCP"
      cidr_blocks = local.security_group_cidrs.oracle_db
      security_groups = [
        module.bastion_linux.bastion_security_group
      ]
    },

    {
      description = "Allow oem agent ingress"
      from_port   = "3872"
      to_port     = "3872"
      protocol    = "TCP"
      cidr_blocks = local.security_group_cidrs.oracle_oem_agent
      security_groups = [
        module.bastion_linux.bastion_security_group
      ]
    },
  ]

  egress = [
    local.security_group_common.all_egress,
  ]

  tags = merge(local.tags, {
    Name = "data"
  })
}