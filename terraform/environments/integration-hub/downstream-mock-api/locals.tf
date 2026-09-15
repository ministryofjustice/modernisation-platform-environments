locals {
  resource_application_name = "integration-hub-downstream-mock-api"

  service_configuration = merge(
    {
      desired_count       = 1
      task_cpu            = 512
      task_memory         = 1024
      container_port      = 8080
      health_check_path   = "/health/ping"
      bootstrap_image_tag = "latest"
    },
    try(local.application_data.accounts[local.environment].service_configuration, {})
  )
}
