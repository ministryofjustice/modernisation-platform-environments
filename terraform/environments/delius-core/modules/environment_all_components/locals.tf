locals {
  ldap_port = 389

  tags = merge(
    var.tags,
    {
      delius-environment-name = var.env_name
    },
  )
}
