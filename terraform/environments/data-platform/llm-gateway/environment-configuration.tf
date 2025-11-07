locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      bedrock_inference_profiles = {
        claude-sonnet-4-5 = {
          model_id = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
          region   = "eu-west-2"
        }
        claude-sonnet-4 = {
          model_id = "eu.anthropic.claude-sonnet-4-20250514-v1:0"
          region   = "eu-west-1"
        }
      }
      litellm_versions = {
        application = "main-v1.77.7-stable"
        chart       = "0.1.794"
      }
      llm_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect
        # DOM1
        "157.203.176.138/31",
        "157.203.176.140/32",
        "157.203.177.190/31",
        "157.203.177.192/32",
        "195.59.75.0/24",
        "194.33.192.0/25",
        "194.33.196.0/25",
        "194.33.193.0/25",
        "194.33.197.0/25",
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # Analytical Platform Tooling Production
        "54.195.74.96/32",
        "79.125.36.56/32",
        "63.35.122.32/32",
        # Cloud Platform
        "3.8.51.207/32",
        "35.177.252.54/32",
        "35.178.209.113/32",
      ]
    }
    test = {
      bedrock_inference_profiles    = {}
      litellm_versions              = {}
      llm_gateway_ingress_allowlist = []
    }
    preproduction = {
      bedrock_inference_profiles    = {}
      litellm_versions              = {}
      llm_gateway_ingress_allowlist = []
    }
    production = {
      bedrock_inference_profiles    = {}
      litellm_versions              = {}
      llm_gateway_ingress_allowlist = []
    }
  }
}
