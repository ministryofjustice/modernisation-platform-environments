# DPR RDS Database Instance
module "dpr_rds_db" {
  source = "./modules/rds/postgres"

  enable_rds         = local.enable_dpr_rds_db
  allocated_size     = local.dpr_rds_init_size
  max_allocated_size = local.dpr_rds_max_size
  subnets            = local.dpr_subnets
  vpc_id             = local.dpr_vpc
  kms                = local.rds_kms_arn
  name               = local.dpr_rds_name
  db_name            = local.dpr_rds_db_identifier
  db_instance_class  = local.dpr_rds_inst_class
  master_user        = local.dpr_rds_user
  storage_type       = local.dpr_rds_store_type
  parameter_group    = local.dpr_rds_parameter_group
  ca_cert_identifier = "rds-ca-rsa2048-g1" # Expiry on June 16, 2026

  tags = merge(
    local.all_tags,
    {
      Resource_Group = "RDS"
      Jira           = "DPR2-2072"
      Resource_Type  = "RDS Instance"
      Name           = local.dpr_rds_name
    }
  )
}
