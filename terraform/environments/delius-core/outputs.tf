output "container_vars_default" {
  value = module.environment_test[0].container_vars_default
  sensitive = true
}