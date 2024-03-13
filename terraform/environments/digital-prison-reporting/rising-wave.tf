module "rising_wave_etcd" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-rising-wave-etcd-${local.env}"
  description                 = "Rising Wave etcd dependency"
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
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_all_object_actions_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
  ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "etcd"

  ec2_sec_rules = {
    "ETCD" = {
      "from_port" = 2379,
      "to_port"   = 2380,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    ENV = local.env
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-rising-wave-etcd-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "rising-wave"
      Jira           = "DPR2-463"
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.s3_all_object_actions_policy,
  ]

}

# The central metadata management service
module "rising_wave_meta_node" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-rising-wave-meta-node-${local.env}"
  description                 = "Rising Wave Meta node"
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
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_all_object_actions_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
  ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "rising-wave"

  ec2_sec_rules = {
    "RISINGWAVE_META" = {
      "from_port" = 5690,
      "to_port"   = 5690,
      "protocol"  = "TCP"
    }
    "RISINGWAVE_DASHBOARD" = {
      "from_port" = 5691,
      "to_port"   = 5691,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    ENV                   = local.env
    RISING_WAVE_NODE_TYPE = "meta"
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-rising-wave-meta-node-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "rising-wave"
      Jira           = "DPR2-463"
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.s3_all_object_actions_policy,
  ]

}

# The worker nodes that execute query plans and handles data ingestion and output
module "rising_wave_compute_nodes" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-rising-wave-compute-node-${local.env}"
  description                 = "Rising Wave Compute Nodes"
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
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_all_object_actions_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
  ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "rising-wave"

  ec2_sec_rules = {
    "RISINGWAVE_COMPUTE" = {
      "from_port" = 5688,
      "to_port"   = 5688,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    ENV                   = local.env
    RISING_WAVE_NODE_TYPE = "compute"
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-rising-wave-compute-node-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "rising-wave"
      Jira           = "DPR2-463"
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.s3_all_object_actions_policy,
  ]

}

# The stateless worker node that compacts data for the storage engine
module "rising_wave_compactor_node" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-rising-wave-compactor-node-${local.env}"
  description                 = "Rising Wave Compactor Node"
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
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_all_object_actions_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
  ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "rising-wave"

  ec2_sec_rules = {
    "RISINGWAVE_COMPACTOR" = {
      "from_port" = 6660,
      "to_port"   = 6660,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    ENV                   = local.env
    RISING_WAVE_NODE_TYPE = "compactor"
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-rising-wave-compactor-node-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "rising-wave"
      Jira           = "DPR2-463"
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.s3_all_object_actions_policy,
  ]

}

# The stateless proxy that parses SQL queries and performs planning and optimizations of query jobs
module "rising_wave_frontend_node" {
  source = "./modules/compute_node"

  enable_compute_node         = true
  name                        = "${local.project}-rising-wave-frontend-node-${local.env}"
  description                 = "Rising Wave Frontend Node"
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
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  policies                    = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_all_object_actions_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
  ]
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env
  app_key                     = "rising-wave"

  ec2_sec_rules = {
    "RISINGWAVE_FRONTEND" = {
      "from_port" = 4566,
      "to_port"   = 4566,
      "protocol"  = "TCP"
    }
  }

  env_vars = {
    ENV                   = local.env
    RISING_WAVE_NODE_TYPE = "frontend"
  }

  tags = merge(
    local.all_tags,
    {
      Name           = "${local.project}-rising-wave-frontend-node-${local.env}"
      Resource_Type  = "EC2 Instance"
      Resource_Group = "rising-wave"
      Jira           = "DPR2-463"
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.s3_all_object_actions_policy,
  ]

}

resource "aws_iam_user" "rising_wave_s3_connector_user" {
  name = "rising_wave_s3_connector_user"
  path = "/drp/risingwave/"

  tags = {
    Resource_Group = "rising-wave"
    Jira           = "DPR2-463"
  }
}