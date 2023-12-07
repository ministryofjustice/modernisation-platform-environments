#### This file can be used to store locals specific to the member account ####
locals {
  db_service_name         = "testing-db"
  db_fully_qualified_name = "${local.application_name}-${local.db_service_name}"
  db_image_tag            = "5.7.4"
  db_port                 = 1521
  db_name                 = "MODNDA"

  frontend_url                  = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  frontend_service_name         = "frontend"
  frontend_fully_qualified_name = "${local.application_name}-${local.frontend_service_name}"
  frontend_image_tag            = "5.7.6"
  frontend_container_port       = 8080

  ldap_port = 389

  delius_environments_per_account = {
    # account = [env1, env2]
    prod     = []
    pre_prod = []
    test     = []
    dev      = ["dev", "test"]
  }

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]
}
