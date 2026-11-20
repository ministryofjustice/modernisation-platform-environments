locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      cloud_platform_namespace = "developer-experience-app-dev"
    }
    production = {
      cloud_platform_namespace = "developer-experience-app-prod"
    }
    preproduction = {
      cloud_platform_namespace = "developer-experience-app-preprod"
    }
    test = {
      cloud_platform_namespace = "developer-experience-app-test"
    }
  }
}
