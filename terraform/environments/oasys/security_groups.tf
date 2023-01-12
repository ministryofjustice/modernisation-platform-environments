# wondered about creating a security group module, but i don't think it'd be much simpler 
# since we'd need to define the in/egresses. Unless maybe we add default entries.

resource "aws_security_group" "webserver" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for webserver instances"
  name        = "webserver"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  ingress {
    description = "access from Cloud Platform Prometheus script exporter collector"
    from_port   = "9172"
    to_port     = "9172"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "webserver-security-group"
    }
  )
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

resource "aws_security_group" "ec2_test" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Security group for ec2_test instances"
  name        = "ec2_test"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Internal access to self on all ports"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  ingress {
    description     = "Internal access to ssh"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "External access to ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = local.environment_config.external_remote_access_cidrs
  }

  ingress {
    description     = "Internal access to weblogic admin http"
    from_port       = "7001"
    to_port         = "7001"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "External access to weblogic admin http"
    from_port   = "7001"
    to_port     = "7001"
    protocol    = "TCP"
    cidr_blocks = local.environment_config.external_weblogic_access_cidrs
  }

  ingress {
    description     = "Internal access to weblogic http"
    from_port       = "7777"
    to_port         = "7777"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "External access to prometheus node exporter"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  ingress {
    description = "External access to prometheus script exporter"
    from_port   = "9172"
    to_port     = "9172"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "ec2-test-common"
    }
  )
}