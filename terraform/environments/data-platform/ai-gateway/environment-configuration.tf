locals {
  environment_configurations = {
    development = {
      litellm_version     = "1.97.0"
      ai_gateway_hostname = "development.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24"       # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # GitHub Actions
        "20.58.27.30/32" # octo-production
      ]
      ai_gateway_internal_ingress_allowlist = [
        "10.0.0.0/8",   # MOJ internal network
        "172.20.0.0/16" # Cloud Platform
      ]
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "18.4"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    test = {
      litellm_version     = "1.97.0"
      ai_gateway_hostname = "test.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24"       # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # GitHub Actions
        "20.58.27.30/32" # octo-production
      ]
      ai_gateway_internal_ingress_allowlist = [
        "10.0.0.0/8",   # MOJ internal network
        "172.20.0.0/16" # Cloud Platform
      ]
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "18.4"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    preproduction = {
      litellm_version     = "1.97.0"
      ai_gateway_hostname = "preproduction.ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24"       # 10SC
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # GitHub Actions
        "20.58.27.30/32" # octo-production
      ]
      ai_gateway_internal_ingress_allowlist = [
        "10.0.0.0/8",   # MOJ internal network
        "172.20.0.0/16" # Cloud Platform
      ]
      ai_gateway_autoscaling = {
        min_replicas                      = 1
        max_replicas                      = 3
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class = "db.serverless"
      aurora_engine_version = "18.4"
      aurora_instances      = { writer = {} }
      aurora_serverlessv2_scaling_configuration = {
        min_capacity             = 0
        max_capacity             = 4
        seconds_until_auto_pause = 3600
      }
      elasticache_node_type = "cache.t4g.medium"
    }
    production = {
      litellm_version     = "1.97.0"
      ai_gateway_hostname = "ai-gateway.justice.gov.uk"
      ai_gateway_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # Cloud Platform
        "35.178.209.113/32",
        "3.8.51.207/32",
        "35.177.252.54/32",
        # Analytical Platform
        ## Compute
        ### Development
        "18.133.132.50/32",
        "18.132.51.177/32",
        "13.42.93.133/32",
        ### Test
        "18.134.41.36/32",
        "3.11.34.83/32",
        "18.133.37.201/32",
        ### Production
        "18.168.85.104/32",
        "13.42.220.232/32",
        "18.168.158.203/32",
        ## Tools
        ### Production
        "54.195.74.96/32",
        "79.125.36.56/32",
        "63.35.122.32/32"
      ]
      ai_gateway_admin_ingress_allowlist = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
        # GitHub Actions
        "20.58.27.30/32" # octo-production
      ]
      ai_gateway_internal_ingress_allowlist = [
        "10.0.0.0/8",   # MOJ internal network
        "172.20.0.0/16" # Cloud Platform
      ]
      ai_gateway_autoscaling = {
        min_replicas                      = 2
        max_replicas                      = 10
        target_cpu_utilization_percentage = 60
      }
      aurora_instance_class                     = "db.t4g.medium"
      aurora_engine_version                     = "18.4"
      aurora_instances                          = { writer = {}, reader = {} }
      aurora_serverlessv2_scaling_configuration = null
      elasticache_node_type                     = "cache.t4g.medium"
    }
  }
}
