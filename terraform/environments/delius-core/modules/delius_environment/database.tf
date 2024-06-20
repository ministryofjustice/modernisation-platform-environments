locals {
  db_public_key_data = jsondecode(file("./db_users.json"))
  instance_policies  = [for v in values(merge(module.oracle_db_shared.instance_policies, var.db_config.instance_policies)) : v.arn]
  availability_zone_map = {
    0 = "a"
    1 = "b"
    2 = "c"
  }
}

module "oracle_db_shared" {
  source             = "../components/oracle_db_shared"
  account_config     = var.account_config
  environment_config = var.environment_config
  account_info       = var.account_info
  platform_vars      = var.platform_vars
  env_name           = var.env_name
  tags               = local.tags
  public_keys        = local.db_public_key_data.keys[var.env_name]

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

  tags = merge(local.tags, { "Patch Group" = "oracle_db_patchgroup" })
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.db_config.ansible_user_data_config
  )

  enable_platform_backups = var.enable_platform_backups

  ssh_keys_bucket_name = module.oracle_db_shared.ssh_keys_bucket_name

  instance_profile_policies = local.instance_policies

  sns_topic_arn = aws_sns_topic.delius_core_alarms.arn

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
  tags               = merge(local.tags, { "Patch Group" = "oracle_db_patchgroup" })
  user_data = templatefile(
    "${path.module}/templates/userdata.sh.tftpl",
    var.db_config.ansible_user_data_config
  )

  enable_platform_backups = var.enable_platform_backups

  ssh_keys_bucket_name = module.oracle_db_shared.ssh_keys_bucket_name

  instance_profile_policies = local.instance_policies

  sns_topic_arn = aws_sns_topic.delius_core_alarms.arn

  providers = {
    aws.core-vpc = aws.core-vpc
  }
}

resource "aws_secretsmanager_secret" "delius_core_application_passwords_secret" {
  name        = local.application_secret_name
  description = "Application Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "delius_core_application_passwords_policy_doc" {

  count = local.has_mis_environment ? 1 : 0
  statement {
    sid    = "MisAWSAccountToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.mis_account_id}:role/instance-role-delius-mis-${var.env_name}-mis-db-1"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.delius_core_application_passwords_secret.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "delius_core_application_passwords_pol" {
  count = local.has_mis_environment ? 1 : 0

  secret_arn = aws_secretsmanager_secret.delius_core_application_passwords_secret.arn
  policy     = data.aws_iam_policy_document.delius_core_application_passwords_policy_doc[0].json
}

data "aws_iam_policy_document" "db_access_to_secrets_manager" {
  count = local.has_mis_environment ? 1 : 0
  statement {
    sid = "DbAccessToSecretsManager"
    actions = [
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:ListSecret*",
      "secretsmanager:Put*",
      "secretsmanager:RestoreSecret",
      "secretsmanager:Update*"
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.delius_core_application_passwords_secret.arn
    ]
  }
}

resource "aws_secretsmanager_secret_version" "delius_core_application_passwords_secret" {
   secret_id = aws_secretsmanager_secret.delius_core_application_passwords_secret.id
}
