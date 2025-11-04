locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      litellm_versions = {
        application = "main-v1.79.0-stable"
        chart       = "0.1.807"
      }
      litellm_organization_ids = {
        /* These are not currently managed in code */
        ministryofjustice = "ec09fd0e-617c-4703-8b48-0a722d9342d4"
      }
      llm_gateway_hostname = "llm-gateway.development.data-platform.service.justice.gov.uk"
      llm_gateway_ingress_allowlist = [
        # Personal
        "83.105.252.164/32", # @jacobwoffenden
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
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
        # Analytical Platform Compute Development
        "18.133.132.50/32",
        "18.132.51.177/32",
        "13.42.93.133/32",
        # Analytical Platform Tooling Production
        "54.195.74.96/32",
        "79.125.36.56/32",
        "63.35.122.32/32",
        # Cloud Platform
        "3.8.51.207/32",
        "35.177.252.54/32",
        "35.178.209.113/32",
      ]
      llm_gateway_models = {
        azure = {
          gpt-5 = {
            model_id    = "gpt-5"
            api_version = "2024-12-01-preview"
          }
          gpt-5-codex = {
            model_id    = "gpt-5-codex"
            api_version = "2025-03-01-preview"
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
          claude-sonnet-4-5 = {
            model_id = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
            region   = "eu-west-2"
          }
        }
      }
      llm_gateway_teams = {
        central-digital = {
          organisation = "ministryofjustice"
          models = [
            "amazon-titan-embed-text-v2",
            "bedrock-claude-sonnet-4-5"
          ]
          keys = {
            website-builder-helper = {
              models = [
                "amazon-titan-embed-text-v2",
                "bedrock-claude-sonnet-4-5"
              ]
            }
          }
        }
        data-platform = {
          organisation = "ministryofjustice"
          models = [
            "azure-gpt-5",
            "azure-gpt-5-codex",
            "bedrock-claude-haiku-4-5",
            "bedrock-claude-sonnet-4-5"
          ]
          keys = {
            mlops-poc = {
              models = ["bedrock-claude-sonnet-4-5"]
            }
          }
        }
        data-science = {
          organisation = "ministryofjustice"
          models = [
            "bedrock-claude-haiku-4-5",
            "bedrock-claude-sonnet-4-5"
          ]
          keys = {}
        }
      }
    }
    test = {
      litellm_versions              = {}
      litellm_organization_ids      = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
      llm_gateway_teams             = {}
    }
    preproduction = {
      litellm_versions              = {}
      litellm_organization_ids      = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
      llm_gateway_teams             = {}
    }
    production = {
      litellm_versions              = {}
      litellm_organization_ids      = {}
      llm_gateway_hostname          = ""
      llm_gateway_ingress_allowlist = []
      llm_gateway_models            = {}
      llm_gateway_teams             = {}
    }
  }
}
