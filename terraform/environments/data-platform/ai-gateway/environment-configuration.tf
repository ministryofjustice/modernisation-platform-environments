locals {
  environment_configuration = local.environment_configurations[local.environment]
  ai_gateway_models         = yamldecode(file("${path.module}/configuration/models.yml"))
  environment_configurations = {
    proxy_admin_emails = [
      "Muhammad.Ahmad@justice.gov.uk",
      "Jeremy.Collins@justice.gov.uk",
      "Gary.Henderson1@justice.gov.uk",
      "Lauren.Taylor-Brown@justice.gov.uk",
      "Jacob.Woffenden@justice.gov.uk"
    ]
    development = {
      litellm_version     = "1.87.0"
      ai_gateway_hostname = "development.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_models = local.ai_gateway_models
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "17.7"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    test = {
      litellm_version     = "1.87.0"
      ai_gateway_hostname = "test.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_models = local.ai_gateway_models
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "17.7"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    preproduction = {
      litellm_version     = "1.87.0"
      ai_gateway_hostname = "preproduction.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_models = local.ai_gateway_models
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "17.7"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    production = {
      litellm_version     = "1.87.0"
      ai_gateway_hostname = "ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
      ai_gateway_models = local.ai_gateway_models
      ai_gateway_autoscaling = {
        min_replicas                      = 2
        max_replicas                      = 10
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class                     = "db.t4g.medium"
      aurora_engine_version                     = "17.7"
      aurora_instances                          = { writer = {}, reader = {} }
      aurora_serverlessv2_scaling_configuration = null
      elasticache_node_type                     = "cache.t4g.medium"
    }
  }
}
