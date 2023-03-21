locals {
  default_tags = {
    instance-name = var.instance.db_name
  }
  tags = merge(local.default_tags, var.tags)
}