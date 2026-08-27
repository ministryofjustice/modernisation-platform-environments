locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.development.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-development"
      grafana_chart_version    = "12.11.0"

      # Enable dashboard management in grafana-dashboards.tf (keep false until monitoring/grafana-api-token is populated).
      grafana_dashboards_enabled = true

      # Monitored accounts. Grafana assumes data-platform-monitoring in each account;
      # account IDs are resolved from environment_management. Use ws-... to add AMP,
      # leave prometheus_workspace_id empty for CloudWatch/X-Ray only.
      grafana_monitored_accounts = [
        { name = "data-platform-development", prometheus_workspace_id = "ws-1103e531-1155-4d18-ad5f-87ba29e2a38b7a" },
        { name = "data-platform-test", prometheus_workspace_id = "ws-80d995fc-475d-4232-ad3f-80e2342e428902" },
        { name = "data-platform-preproduction", prometheus_workspace_id = "ws-007c0bbe-4cc7-484b-a012-0105073723ba72" },
        { name = "data-platform-governance-development", prometheus_workspace_id = "" },
        { name = "data-platform-governance-test", prometheus_workspace_id = "" },
        { name = "data-platform-governance-preproduction", prometheus_workspace_id = "" },
      ]

      # Azure AI Foundry resource queried by the shared "azure-monitor-ai-foundry"
      azure_foundry_resource = {
        subscription_id = "0cc7ff17-55e7-486f-9fc0-f32a4bc34b81"
        resource_group  = "rg-aif-jedigw"
        resource_name   = "aif-jedigw-rmgns"
      }

      # CIDRs allowed to reach Grafana (rendered into ingress whitelist-source-range).
      grafana_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
        "20.58.27.30/32",  # GitHub Runner (octo-production)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]

      # Alert routing by account: enabled groups, scoped namespaces, and overrides.
      alerts_configured_accounts = [
        { name = "data-platform-development", enabled_groups = ["AI Gateway", "Bedrock","Azure AI Foundry","Vertex AI"], namespaces = ["ai-gateway"] },
        { name = "data-platform-test", enabled_groups = ["AI Gateway", "Bedrock"], namespaces = ["ai-gateway"] },
        { name = "data-platform-preproduction", enabled_groups = ["AI Gateway", "Bedrock"], namespaces = ["ai-gateway"] }
      ]
    }
    test = {
      monitoring_stack_enabled = false
    }
    preproduction = {
      monitoring_stack_enabled = false
    }
    production = {
      monitoring_stack_enabled = true
      monitoring_hostname      = "monitoring.data-platform.service.justice.gov.uk"
      grafana_namespace        = "data-platform-monitoring-production"
      grafana_chart_version    = "12.11.0"

      # Enable dashboard management in grafana-dashboards.tf (keep false until monitoring/grafana-api-token is populated).
      grafana_dashboards_enabled = true

      grafana_monitored_accounts = [
        { name = "data-platform-development", prometheus_workspace_id = "ws-1103e531-1155-4d18-ad5f-87ba29e2a38b7a" },
        { name = "data-platform-test", prometheus_workspace_id = "ws-80d995fc-475d-4232-ad3f-80e2342e428902" },
        { name = "data-platform-preproduction", prometheus_workspace_id = "ws-007c0bbe-4cc7-484b-a012-0105073723ba72" },
        { name = "data-platform-production", prometheus_workspace_id = "ws-d3a32572-9e85-49f9-8654-bffcf5877783a2" },
        { name = "data-platform-governance-development", prometheus_workspace_id = "" },
        { name = "data-platform-governance-test", prometheus_workspace_id = "" },
        { name = "data-platform-governance-preproduction", prometheus_workspace_id = "" },
        { name = "data-platform-governance-production", prometheus_workspace_id = "" },
      ]

      # Azure AI Foundry - currently not yet deployed foundry in production so its commented out. Once deployed, uncomment and populate the values below.
      #azure_foundry_resource = {
      #  subscription_id = ""
      #  resource_group  = ""
      #  resource_name   = ""
      #}

      # CIDRs allowed to reach Grafana (rendered into ingress whitelist-source-range).
      grafana_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
        "20.58.27.30/32",  # GitHub Runner (octo-production)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      # Alert routing by account: enabled groups, scoped namespaces, and overrides.
      alerts_configured_accounts = [
        { name = "data-platform-development", enabled_groups = ["AI Gateway", "Bedrock"], namespaces = ["ai-gateway"] },
        { name = "data-platform-test", enabled_groups = ["AI Gateway", "Bedrock"], namespaces = ["ai-gateway"] },
        { name = "data-platform-preproduction", enabled_groups = ["AI Gateway", "Bedrock"], namespaces = ["ai-gateway"] },
        { name = "data-platform-production", enabled_groups = ["AI Gateway", "Bedrock", "Vertex AI"], namespaces = ["ai-gateway"] }
      ]
    }
  }
}
