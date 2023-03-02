locals {
  tags = merge(var.environment.tags, var.tags)
}
