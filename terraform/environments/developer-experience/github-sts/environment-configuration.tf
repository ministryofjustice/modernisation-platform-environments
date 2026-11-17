locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      cloud_platform_namespace = "github-sts-dev"
    }
    test = {
      cloud_platform_namespace = "github-sts-test"
    }
    preproduction = {
      cloud_platform_namespace = "github-sts-preprod"
    }
    production = {
      cloud_platform_namespace = "github-sts-prod"
    }
  }
}
