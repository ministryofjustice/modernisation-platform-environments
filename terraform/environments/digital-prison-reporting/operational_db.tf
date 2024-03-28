module "operational_db_server" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-operational-db-server-${local.env}"
  description                 = "Operational DB Instance"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 300
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}", "arn:aws:iam::${local.account_id}:policy/${local.apigateway_get_policy}", ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "operational-db"

  env_vars = {
    POSTGRES_PASS     = "postgres" # WEAK, WIP
    ENV               = local.env
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-operational-db-server-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "operational-db"
      Name           = "${local.project}-operational-db-server-${local.env}"
    }
  )
}