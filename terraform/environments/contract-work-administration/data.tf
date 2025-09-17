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
