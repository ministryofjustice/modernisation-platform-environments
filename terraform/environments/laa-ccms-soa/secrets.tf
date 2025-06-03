#### This file can be used to store secrets specific to the member account ####


#### Secrets for SOA application ####

resource "aws_secretsmanager_secret" "soa_password" {
  name        = "ccms/soa/password"
  description = "SOA weblogic EM console and database password"

}


resource "aws_secretsmanager_secret" "xxsoa_ds_password" {
  name        = "ccms/soa/xxsoa/ds/password"
  description = "TDS XXSOA data source password"

}

resource "aws_secretsmanager_secret" "ebs_ds_password" {
  name        = "ccms/soa/ebs/ds/password"
  description = "EBS data source password"

}


resource "aws_secretsmanager_secret" "ebssms_ds_password" {
  name        = "ccms/soa/ebs/sms/ds/password"
  description = "EBS SMS data source password"

}

resource "aws_secretsmanager_secret" "pui_user_password" {
  name        = "ccms/soa/pui/user/password"
  description = "PUI user password"

}

resource "aws_secretsmanager_secret" "ebs_user_password" {
  name        = "ccms/soa/ebs/user/password"
  description = "EBS user password"

}