module "operational_db_server" {
  source = "./modules/compute_node"

  count                       = local.deploy_operational_database ? 1 : 0
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
      Jira           = "DPR2-509"
    }
  )
}