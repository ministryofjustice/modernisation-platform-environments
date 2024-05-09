#### This file can be used to store locals specific to the member account ####
locals {
    application_name_short = "cwa"
    nonprod_workspaces_local_cidr1 = "10.200.2.0/24"
    nonprod_workspaces_local_cidr2 = "10.200.3.0/24"
    cloud_platform_cidr = "172.20.0.0/16"
    database_ec2_name = "${upper(local.application_name_short)} Database Instance"
    cm_ec2_name = "${upper(local.application_name_short)} Concurrent Manager Instance"
    appserver1_ec2_name = "${upper(local.application_name_short)} App Instance 1"
    database_hostname = "${local.application_name_short}-db"
    cm_hostname = "${local.application_name_short}-app2"
    appserver1_hostname = "${local.application_name_short}-app1"
}