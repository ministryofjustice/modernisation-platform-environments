locals {
  tags = merge(
    var.tags,
    {
      delius-environment = var.env_name
    },
  )
}   
