locals {
  global_config = yamldecode(file("${path.module}/configuration/global.yml"))
}
