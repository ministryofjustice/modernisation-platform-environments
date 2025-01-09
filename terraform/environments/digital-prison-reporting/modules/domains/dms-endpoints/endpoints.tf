# DMS Module to Provision Endpoints
module "dms_endpoints" {
  source = "../../dms_s3_v2"

  setup_dms_endpoints                 = var.setup_dms_endpoints
  setup_dms_iam                       = var.setup_dms_iam
  setup_dms_source_endpoint           = var.setup_dms_source_endpoint
  setup_dms_s3_endpoint               = var.setup_dms_s3_endpoint
  source_engine_name                  = var.source_engine_name
  dms_source_name                     = var.dms_source_name
  dms_target_name                     = var.dms_target_name
  project_id                          = var.project_id
  env                                 = var.env # common
  short_name                          = var.short_name
  source_db_name                      = var.source_db_name
  source_app_username                 = var.source_app_username
  source_app_password                 = var.source_app_password
  source_address                      = var.source_address
  source_ssl_mode                     = var.source_ssl_mode
  source_db_port                      = var.source_db_port
  extra_attributes                    = var.extra_attributes
  bucket_name                         = var.bucket_name
  source_postgres_heartbeat_enable    = var.source_postgres_heartbeat_enable
  source_postgres_heartbeat_frequency = var.source_postgres_heartbeat_frequency

  tags = var.tags
}