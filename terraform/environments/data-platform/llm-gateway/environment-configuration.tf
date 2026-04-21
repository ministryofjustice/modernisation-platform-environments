locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      litellm_versions = {
        application = "main-v1.82.3-stable.patch.2"
        chart       = "1.82.3-stable.patch.2"
      }
      llm_gateway_hostname = "llm-gateway.development.data-platform.service.justice.gov.uk"
      llm_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # Analytical Platform Tooling Production
        "54.195.74.96/32",
        "79.125.36.56/32",
        "63.35.122.32/32",
        # Cloud Platform Live
        "3.8.51.207/32",
        "35.177.252.54/32",
        "35.178.209.113/32",
        # Modernisation Platform
        "13.41.38.176/32",
        "3.8.81.175/32",
        "3.11.197.133/32",
        "13.43.9.198/32",
        "13.42.163.245/32",
        "18.132.208.127/32",
      ]
      llm_gateway_models = {
        azure = {
          gpt-4o = {
            model_id    = "gpt-4o-mojdp"
            api_version = "2024-12-01-preview"
          }
          gpt-4-1 = {
            model_id    = "gpt-4.1-mojdp"
            api_version = "2024-12-01-preview"
          }
          gpt-5 = {
            model_id    = "gpt-5-mojdp"
            api_version = "2024-12-01-preview"
          }
          gpt-5-1 = {
            model_id    = "gpt-5.1-mojdp"
            api_version = "2024-12-01-preview"
          }
          gpt-5-2 = {
            model_id    = "gpt-5.2-mojdp"
            api_version = "2024-12-01-preview"
          }
        }
        bedrock = {
          amazon-titan-embed-text-v2 = {
            model_id = "amazon.titan-embed-text-v2:0"
            region   = "eu-west-2"
          }
          claude-haiku-4-5 = {
            model_id = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
            region   = "eu-west-2"
          }
          claude-opus-4-5 = {
            model_id = "eu.anthropic.claude-opus-4-5-20251101-v1:0"
            region   = "eu-west-2"
          }
          claude-opus-4-6 = {
            model_id = "eu.anthropic.claude-opus-4-6-v1"
            region   = "eu-west-2"
          }
          claude-sonnet-4 = {
            model_id = "eu.anthropic.claude-sonnet-4-20250514-v1:0"
            region   = "eu-west-1"
          }
          claude-sonnet-4-5 = {
            model_id = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
            region   = "eu-west-2"
          }
          claude-sonnet-4-6 = {
            model_id = "eu.anthropic.claude-sonnet-4-6"
            region   = "eu-west-2"
          }
          cohere-embed-english-v3 = {
            model_id = "cohere.embed-english-v3"
            region   = "eu-west-2"
          }
          cohere-embed-multilingual-v3 = {
            model_id = "cohere.embed-multilingual-v3"
            region   = "eu-west-2"
          }
          meta-llama3-8b-instruct = {
            model_id = "meta.llama3-8b-instruct-v1:0"
            region   = "eu-west-2"
          }
          meta-llama3-70b-instruct = {
            model_id = "meta.llama3-70b-instruct-v1:0"
            region   = "eu-west-2"
          }
          qwen-qwen3-coder-30b-a3b = {
            model_id = "qwen.qwen3-coder-30b-a3b-v1:0"
            region   = "eu-west-2"
          }
        }
      }
    }
    test = {
      litellm_versions              = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
    }
    preproduction = {
      litellm_versions              = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
    }
    production = {
      litellm_versions              = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
    }
  }
}
