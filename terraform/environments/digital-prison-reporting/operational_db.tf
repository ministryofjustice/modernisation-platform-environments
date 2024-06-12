module "operational_db_server" {
  source = "./modules/compute_node"

  count = (local.environment == "development" ? 1 : 0)

  enable_compute_node         = true
  scale_down                  = false
  name                        = "${local.project}-operational-db-server-${local.env}"
  description                 = "Operational DB Instance"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = "t3.large"
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 300
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.apigateway_get_policy}",
  ]

  region  = local.account_region
  account = local.account_id
  env     = local.env
  app_key = "operational-db"
  ec2_sec_rules = {
    # Allow access to Postgres only from our subnet
    "TCP_5432" = {
      "from_port" = 5432,
      "to_port"   = 5432,
      "protocol"  = "TCP"
    },
    "TCP_22" = {
      "from_port" = 22,
      "to_port"   = 22,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    POSTGRES_P = "postgres" # WEAK - this is just used for dev environment only spike
    ENV        = local.env
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-operational-db-server-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "operational-db"
    }
  )
}

# Allows Glue jobs to be configured to access resources in the VPC
resource "aws_glue_connection" "glue_vpc_access_connection" {
  count = (local.environment == "development" ? 1 : 0)
  name            = "${local.project}-glue-vpc-connection-${local.env}"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_vpc_access_connection_sg[0].id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

resource aws_security_group "glue_vpc_access_connection_sg" {
  count = (local.environment == "development" ? 1 : 0)
  name        = "glue_vpc_access_connection_sg"
  description = "Security group to allow glue access to resources in the VPC"
  vpc_id      = data.aws_vpc.shared.id

  # The security group must open all ingress and egress ports.
  # To limit traffic, the source security group in the rule is restricted to the same security group with self = true.
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [module.operational_db_server[0].security_group_id]
  }
}

resource "aws_security_group_rule" "allow_glue_security_group_access_to_operational_db" {
  count = (local.environment == "development" ? 1 : 0)

  type              = "ingress"
  security_group_id = module.operational_db_server[0].security_group_id
  description       = "Allow glue security group to communicate with operational data store"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = aws_security_group.glue_vpc_access_connection_sg[0].id
}