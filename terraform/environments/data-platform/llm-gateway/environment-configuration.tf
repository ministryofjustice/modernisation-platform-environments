locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      bedrock_inference_profiles = {
        claude-sonnet-4-5 = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
      }
    }
    test          = {}
    preproduction = {}
    production    = {}
  }
}
