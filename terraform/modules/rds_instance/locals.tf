locals {
  default_tags = {
    instance-name = var.instance.db_name
  }
  tags = merge(local.default_tags, var.tags)

  public_cidr_block      = [data.terraform_remote_state.common.outputs.db_cidr_block]
  private_cidr_block     = [data.terraform_remote_state.common.outputs.private_cidr_block]
  db_cidr_block          = [data.terraform_remote_state.common.outputs.db_cidr_block]
  private_subnet_map     = data.terraform_remote_state.common.outputs.private_subnet_map
  db_subnet_ids          = data.terraform_remote_state.common.outputs.db_subnet_ids

  security_group_ids = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id,
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_delius_db,
  ]

  family               = var.rds_family
  major_engine_version = var.rds_major_engine_version
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  allocated_storage    = var.rds_allocated_storage
  character_set_name   = var.rds_character_set_name

  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]

  multi_az = var.multi_az
}