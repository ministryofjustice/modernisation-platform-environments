#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short         = "cwa"
  nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
  nonprod_workspaces_local_cidr2 = "10.200.3.0/24"
  cloud_platform_cidr            = "172.20.0.0/16"
  database_ec2_name              = "${upper(local.application_name_short)} Database Instance"
  cm_ec2_name                    = "${upper(local.application_name_short)} Concurrent Manager Instance"
  appserver1_ec2_name            = "${upper(local.application_name_short)} App Instance 1"
  appserver2_ec2_name            = "${upper(local.application_name_short)} App Instance 2"
  database_hostname              = "${local.application_name_short}-db"
  cm_hostname                    = "${local.application_name_short}-conc"
  appserver1_hostname            = "${local.application_name_short}-app1"
  appserver2_hostname            = "${local.application_name_short}-app3"

  oradata_device_name_letter = "f"
  oracle_device_name_letter  = "j"
  oraarch_device_name_letter = "g"
  oratmp_device_name_letter  = "h"
  oraredo_device_name_letter = "i"
  share_device_name_letter   = "k"
  root_device_name           = "/dev/mapper/VolGroup00-LogVol00"
  ec2_network_interface      = "eth0"

}