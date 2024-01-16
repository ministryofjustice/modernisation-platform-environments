# DMS Module to Provision Endpoints
module "dms_instance" {
  source                       = "../../dms_s3_v2"

  name                         = var.name
  project_id                   = var.project_id
  env                          = var.env  
  setup_dms_instance           = var.setup_dms_instance
  availability_zones           = var.availability_zones
  replication_instance_version = var.replication_instance_version
  replication_instance_class   = var.replication_instance_class
  subnet_ids                   = var.subnet_ids
  vpc_cidr                     = var.vpc_cidr
  vpc                          = var.vpc
  short_name                   = var.short_name

  tags = var.tags
}