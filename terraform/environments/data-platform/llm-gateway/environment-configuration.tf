locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      bedrock_inference_profiles = {
        claude-sonnet-4 = {
          model_id = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
          region   = "eu-west-1"
        }
        claude-sonnet-3-7 = {
          model_id = "eu.anthropic.claude-3-7-sonnet-20250219-v1:0"
          region   = "eu-west-1"
        }
      }
      litellm_versions = {
        application = "main-v1.77.3-stable"
        chart       = "0.1.785"
      }
    }
    test = {
      bedrock_inference_profiles = {}
      litellm_versions           = {}
    }
    preproduction = {
      bedrock_inference_profiles = {}
      litellm_versions           = {}
    }
    production = {
      bedrock_inference_profiles = {}
      litellm_versions           = {}
    }
  }
}
