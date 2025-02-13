#### This file can be used to store locals specific to the member account ####
#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short = "cwa-poc"
  database_ec2_name      = "${upper(local.application_name_short)} Database Instance"

  database_hostname = "${local.application_name_short}-db"

  oradata_device_name_letter = "f"
  oracle_device_name_letter  = "j"
  oraarch_device_name_letter = "g"
  oratmp_device_name_letter  = "h"
  oraredo_device_name_letter = "i"
  share_device_name_letter   = "k"

}