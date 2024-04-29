locals {
  db_public_key_data = jsondecode(file("./db_users.json"))
}


module "oracle_db_shared" {
  source             = "../components/oracle_db_shared"
  account_config     = var.account_config
  environment_config = var.environment_config
  account_info       = var.account_info
  platform_vars      = var.platform_vars
  env_name           = var.env_name
  tags               = local.tags
  public_keys        = local.db_public_key_data.keys[var.account_info.mp_environment]

  bastion_sg_id = module.bastion_linux.bastion_security_group

  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

}

module "oracle_db_primary" {
  source         = "../components/oracle_db_instance"
  account_config = var.account_config
  account_info   = var.account_info
  db_ami = {
    name_regex = var.db_config.ami_name_regex
    owner      = "self"
  }
  db_type           = "primary"
  db_suffix         = "db"
  count             = 1
  db_count_index    = count.index + 1
  ec2_instance_type = var.db_config.instance_type

  security_group_ids = [module.oracle_db_shared.security_group.id]

  ec2_key_pair_name = module.oracle_db_shared.db_key_pair.key_name

  user_data_replace_on_change = false

  ebs_volumes       = var.db_config.ebs_volumes
  ebs_volume_config = var.db_config.ebs_volume_config

  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.ordered_private_subnet_ids[count.index % 3]
  availability_zone  = "eu-west-2${lookup(local.availability_zone_map, count.index % 3, "a")}"

  tags = local.tags
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.db_config.ansible_user_data_config
  )

  enable_platform_backups = var.enable_platform_backups

  ssh_keys_bucket_name = module.oracle_db_shared.ssh_keys_bucket_name

  instance_profile_policies = [for v in values(module.oracle_db_shared.instance_policies) : v.arn]

  providers = {
    aws.core-vpc = aws.core-vpc
  }
}

module "oracle_db_standby" {
  source         = "../components/oracle_db_instance"
  account_config = var.account_config
  account_info   = var.account_info

  db_ami = {
    name_regex = var.db_config.ami_name_regex
    owner      = "self"
  }
  db_type         = "standby"
  db_suffix       = "db"
  server_type_tag = "delius_core_db"

  count          = var.db_config.standby_count
  db_count_index = count.index + 1

  ec2_instance_type = var.db_config.instance_type

  security_group_ids = [module.oracle_db_shared.security_group.id]

  ec2_key_pair_name = module.oracle_db_shared.db_key_pair.key_name

  user_data_replace_on_change = false

  ebs_volumes       = var.db_config.ebs_volumes
  ebs_volume_config = var.db_config.ebs_volume_config

  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.ordered_private_subnet_ids[(count.index + length(module.oracle_db_primary)) % 3]
  availability_zone  = "eu-west-2${lookup(local.availability_zone_map, (count.index + length(module.oracle_db_primary)) % 3, "a")}"
  tags               = local.tags
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.db_config.ansible_user_data_config
  )

  enable_platform_backups = var.enable_platform_backups

  ssh_keys_bucket_name = module.oracle_db_shared.ssh_keys_bucket_name

  instance_profile_policies = [for v in values(module.oracle_db_shared.instance_policies) : v.arn]

  providers = {
    aws.core-vpc = aws.core-vpc
  }
}
locals {
  availability_zone_map = {
    0 = "a"
    1 = "b"
    2 = "c"
  }
}
