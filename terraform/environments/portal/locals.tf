#### This file can be used to store locals specific to the member account ####
locals {
  # General
  region = "eu-west-2"

  # RDS
  application_name           = "igdb"
  appstream_cidr             = "10.200.32.0/19"
  cidr_ire_workspace         = "10.200.96.0/19"
  workspaces_cidr            = "10.200.16.0/20"
  cp_vpc_cidr                = "172.20.0.0/20"
  storage_size               = "200"
  auto_minor_version_upgrade = false
  backup_retention_period    = "35"
  character_set_name         = "AL32UTF8"
  instance_class             = "db.t3.large"
  engine                     = "oracle-ee"
  engine_version             = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  username                   = "sysdba"
  max_allocated_storage      = "3500"
  backup_window              = "22:00-01:00"
  maintenance_window         = "Mon:01:15-Mon:06:00"
  storage_type               = "gp2"
  rds_snapshot_name          = "laws3169-mojfin-migration-v1"
  lzprd-vpc                  = "10.205.0.0/20"