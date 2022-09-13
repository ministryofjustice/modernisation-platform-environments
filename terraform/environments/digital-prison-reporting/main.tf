#######################
# Glue Database Catalog
#######################
module "glue_database" {
  source = "./modules/glue_database"

  create = "${var.create_database}"

  name = "${var.glue_db_name}"

  description  = "${var.db_description}"
}
