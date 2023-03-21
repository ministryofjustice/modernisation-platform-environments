locals {
  default_tags = {
    identifier = var.identifier
  }
  tags = merge(local.default_tags, var.tags)
}