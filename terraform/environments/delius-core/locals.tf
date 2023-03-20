#### This file can be used to store locals specific to the member account ####
locals {
  db_service_name         = "testing-db"
  db_fully_qualified_name = "${local.application_name}-${local.db_service_name}"
  db_image_tag            = "5.7.4"
  db_container_port       = 1521

  frontend_service_name         = "testing-frontend"
  frontend_fully_qualified_name = "${local.application_name}-${local.frontend_service_name}"
  frontend_image_tag            = "5.7.6"
  frontend_container_port       = 7001
}
