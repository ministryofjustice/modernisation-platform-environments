#### This file can be used to store data specific to the member account ####

data "local_file" "database_custom_metrics" {
  filename = "${path.module}/db-cw-custom.sh"
}

data "local_file" "app_custom_metrics" {
  filename = "${path.module}/app-cw-custom.sh"
}

data "local_file" "cm_custom_metrics" {
  filename = "${path.module}/cm-cw-custom.sh"
}

data "aws_security_group" "hub20_dev_cwa_lambda_sg" {
  id       = "sg-05152af51195017fa"  #SG ID from the laa-enterprise-service-bus-development account 
}