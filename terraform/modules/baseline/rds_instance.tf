module "db_instance" {
  for_each = var.ec2_instances

  source = "../../modules/ec2_instance"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  create            = true
  identifier        = local.common_name
  engine            = local.engine
  engine_version    = local.engine_version
  instance_class    = local.instance_class
  allocated_storage = local.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id        = module.kms_key.kms_arn
  license_model     = var.license_model

  name                                = upper(local.db_identity)
  username                            = local.db_identity
  password                            = aws_ssm_parameter.db_password.value
  port                                = var.port
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  replicate_source_db = var.replicate_source_db

  snapshot_identifier = var.snapshot_identifier

  vpc_security_group_ids = local.security_group_ids

  db_subnet_group_name = module.db_subnet_group.db_subnet_group_id
  parameter_group_name = aws_db_parameter_group.iaps_parameter_group_19c.name
  option_group_name    = var.rds_major_engine_version == "19" ? aws_db_option_group.iaps_option_group_19c.name :  aws_db_option_group.iaps_option_group.name
  multi_az             = local.multi_az 
  iops                 = var.iops
  publicly_accessible  = var.publicly_accessible

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = true
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  final_snapshot_identifier   = "${local.common_name}-final-snapshot"

  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.backup_window

  monitoring_interval  = var.rds_monitoring_interval
  monitoring_role_arn  = module.rds_monitoring_role.iamrole_arn
  monitoring_role_name = module.rds_monitoring_role.iamrole_name

  timezone           = var.timezone
  character_set_name = local.character_set_name

  tags = merge(
    local.tags,
    {
      "Name" = upper(local.db_identity)
      "autostop-${var.environment_type}" = var.iaps_override_autostop_tags
    }
  )

  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports
}