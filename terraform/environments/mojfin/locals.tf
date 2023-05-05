#### This file can be used to store locals specific to the member account ####
locals {
  cidr_ire_workspace ="10.200.96.0/19"
  cidr_six_degrees=   "10.225.60.0/24"
  obiee_inbound_cidr=  "10.225.40.0/24"
  workspaces_cidr= "10.200.16.0/20"
  cp_vpc_cidr=         "172.20.0.0/20"
  transit_gw_to_mojfinprod=             "10.201.0.0/16"
  storage_size = "2500"
  auto_minor_version_upgrade = false
  backup_retention_period= "35"
  character_set_name = "WE8MSWIN1252"
  instance_class= "db.m5.large"
  engine= "oracle-se2"
  engine_version = "19.0.0.0.ru-2020-04.rur-2020-04.r1"
  username= "sysdba"
  max_allocated_storage=  "3500"
  backup_window = "22:00-01:00"
  maintenance_window = "Mon:01:15-Mon:06:00"
  storage_type = "gp2"
  rds_snapshot_name= "laws3169-mojfin-migration-v1"
  prod_domain_name= "laa-finance-data.service.justice.gov.uk"
}