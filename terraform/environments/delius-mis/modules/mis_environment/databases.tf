locals {
  db_public_key_data    = jsondecode(file("./db_users.json"))
  dsd_instance_policies = [for v in values(merge(module.oracle_db_shared["dsd-db"].instance_policies, var.dsd_db_config.instance_policies)) : v.arn]
  boe_instance_policies = [for v in values(merge(module.oracle_db_shared["boe-db"].instance_policies, var.boe_db_config.instance_policies)) : v.arn]
  mis_instance_policies = [for v in values(merge(module.oracle_db_shared["mis-db"].instance_policies, var.mis_db_config.instance_policies, { db_access_to_delius_secrets_manager = aws_iam_policy.db_access_to_delius_secrets_manager })) : v.arn]
  availability_zone_map = {
    0 = "a"
    1 = "b"
    2 = "c"
  }
}

module "oracle_db_shared" {
  source             = "../../../delius-core/modules/components/oracle_db_shared"
  for_each           = toset(["dsd-db", "boe-db", "mis-db"])
  account_config     = var.account_config
  environment_config = var.environment_config
  account_info       = var.account_info
  platform_vars      = var.platform_vars
  env_name           = var.env_name
  tags               = local.tags
  public_keys        = local.db_public_key_data.keys[var.account_info.mp_environment]
  app_name           = var.app_name

  db_suffix = each.key

  bastion_sg_id = module.bastion_linux.bastion_security_group

  deploy_oracle_stats = false

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
}

module "oracle_db_dsd" {
  source = "../../../delius-core/modules/components/oracle_db_instance"

  account_config = var.account_config
  account_info   = var.account_info
  db_ami = {
    name_regex = var.dsd_db_config.ami_name_regex
    owner      = "self"
  }
  db_type             = "primary"
  db_suffix           = "dsd-db"
  server_type_tag     = "mis_db"
  database_tag_prefix = "dsd"

  count             = try(var.dsd_db_config.instance_count, 1)
  db_count_index    = count.index + 1
  ec2_instance_type = var.dsd_db_config.instance_type

  security_group_ids = [module.oracle_db_shared["dsd-db"].security_group.id]

  ec2_key_pair_name = module.oracle_db_shared["dsd-db"].db_key_pair.key_name

  user_data_replace_on_change = false

  ebs_volumes       = var.dsd_db_config.ebs_volumes
  ebs_volume_config = var.dsd_db_config.ebs_volume_config

  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.ordered_private_subnet_ids[count.index % 3]
  availability_zone  = "eu-west-2${lookup(local.availability_zone_map, count.index % 3, "a")}"

  tags = local.tags
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.dsd_db_config.ansible_user_data_config
  )

  ssh_keys_bucket_name = module.oracle_db_shared["dsd-db"].ssh_keys_bucket_name

  instance_profile_policies = local.dsd_instance_policies

  deploy_oracle_stats = false

  enable_cloudwatch_alarms = try(var.dsd_db_config.enable_cloudwatch_alarms, true)

  sns_topic_arn = aws_sns_topic.delius_mis_alarms.arn

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}

module "oracle_db_boe" {
  source         = "../../../delius-core/modules/components/oracle_db_instance"
  account_config = var.account_config
  account_info   = var.account_info
  db_ami = {
    name_regex = var.boe_db_config.ami_name_regex
    owner      = "self"
  }
  db_type             = "primary"
  db_suffix           = "boe-db"
  server_type_tag     = "mis_db"
  database_tag_prefix = "boe"

  count             = try(var.boe_db_config.instance_count, 1)
  db_count_index    = count.index + 1
  ec2_instance_type = var.boe_db_config.instance_type

  security_group_ids = [module.oracle_db_shared["boe-db"].security_group.id]

  ec2_key_pair_name = module.oracle_db_shared["boe-db"].db_key_pair.key_name

  user_data_replace_on_change = false

  ebs_volumes       = var.boe_db_config.ebs_volumes
  ebs_volume_config = var.boe_db_config.ebs_volume_config

  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.ordered_private_subnet_ids[count.index % 3]
  availability_zone  = "eu-west-2${lookup(local.availability_zone_map, count.index % 3, "a")}"

  tags = local.tags
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.boe_db_config.ansible_user_data_config
  )

  ssh_keys_bucket_name = module.oracle_db_shared["boe-db"].ssh_keys_bucket_name

  instance_profile_policies = local.boe_instance_policies

  deploy_oracle_stats = false

  enable_cloudwatch_alarms = try(var.boe_db_config.enable_cloudwatch_alarms, true)

  sns_topic_arn = aws_sns_topic.delius_mis_alarms.arn

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}


module "oracle_db_mis" {
  source         = "../../../delius-core/modules/components/oracle_db_instance"
  account_config = var.account_config
  account_info   = var.account_info
  db_ami = {
    name_regex = var.mis_db_config.ami_name_regex
    owner      = "self"
  }
  db_type             = "primary"
  db_suffix           = "mis-db"
  server_type_tag     = "mis_db"
  database_tag_prefix = "mis"

  count             = try(var.mis_db_config.instance_count, 1)
  db_count_index    = count.index + 1
  ec2_instance_type = var.mis_db_config.instance_type

  security_group_ids = [module.oracle_db_shared["mis-db"].security_group.id]

  ec2_key_pair_name = module.oracle_db_shared["mis-db"].db_key_pair.key_name

  user_data_replace_on_change = false

  ebs_volumes       = var.mis_db_config.ebs_volumes
  ebs_volume_config = var.mis_db_config.ebs_volume_config

  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.ordered_private_subnet_ids[count.index % 3]
  availability_zone  = "eu-west-2${lookup(local.availability_zone_map, count.index % 3, "a")}"

  tags = local.tags
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.mis_db_config.ansible_user_data_config
  )

  ssh_keys_bucket_name = module.oracle_db_shared["mis-db"].ssh_keys_bucket_name

  instance_profile_policies = local.mis_instance_policies

  deploy_oracle_stats = false

  enable_cloudwatch_alarms = try(var.mis_db_config.enable_cloudwatch_alarms, true)

  sns_topic_arn = aws_sns_topic.delius_mis_alarms.arn

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}

# Policy document to allow access to Delius application secrets only for mis-db

data "aws_iam_policy_document" "db_access_to_delius_secrets_manager" {
  statement {
    sid       = "MisAWSAccountToReadTheDeliusSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${var.account_info.region}:${var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]}:secret:delius-core-${var.env_name}-oracle-db-application-passwords*"]
  }
}

resource "aws_iam_policy" "db_access_to_delius_secrets_manager" {
  name   = "${var.account_info.application_name}-${var.env_name}-mis-db-delius-secrets-manager-access"
  policy = data.aws_iam_policy_document.db_access_to_delius_secrets_manager.json
}
