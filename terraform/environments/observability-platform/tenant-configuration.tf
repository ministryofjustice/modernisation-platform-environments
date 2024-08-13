module "tenant_configuration" {
  for_each = local.environment_configuration.tenant_configuration

  source = "./modules/observability-platform/tenant-configuration"

  providers = {
    aws.sso = aws.sso-readonly
  }

  environment_management = local.environment_management
  name                   = each.key
  identity_centre_team   = each.value.identity_centre_team
  aws_accounts           = each.value.aws_accounts
}

# AMP

import {
  to = module.tenant_configuration["analytical-platform"].module.amazon_prometheus_query_source["analytical-platform-compute-development"].grafana_data_source.this
  id = "hsutp0PSk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.amazon_prometheus_query_source["analytical-platform-compute-test"].grafana_data_source.this
  id = "9blLx0PSz"
}

# CloudWatch

import {
  to = module.tenant_configuration["analytical-platform"].module.cloudwatch_source["analytical-platform-compute-development"].grafana_data_source.this
  id = "0sEx8qYSz"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.cloudwatch_source["analytical-platform-compute-test"].grafana_data_source.this
  id = "lsEbUqLIk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.cloudwatch_source["analytical-platform-ingestion-development"].grafana_data_source.this
  id = "6BVFEz1Sk"
}

import {
  to = module.tenant_configuration["data-engineering"].module.cloudwatch_source["analytical-platform-data-engineering-sandboxa"].grafana_data_source.this
  id = "PD6nxSwSk"
}

import {
  to = module.tenant_configuration["digital-studio-operations"].module.cloudwatch_source["nomis-test"].grafana_data_source.this
  id = "6AAsS9cSz"
}

import {
  to = module.tenant_configuration["digital-studio-operations"].module.cloudwatch_source["oasys-test"].grafana_data_source.this
  id = "871ySr5Ik"
}

import {
  to = module.tenant_configuration["observability-platform"].module.cloudwatch_source["observability-platform-development"].grafana_data_source.this
  id = "iiYsSr5Sk"
}

# X-Ray

import {
  to = module.tenant_configuration["analytical-platform"].module.xray_source["analytical-platform-compute-development"].grafana_data_source.this
  id = "rz-b83YIz"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.xray_source["analytical-platform-compute-test"].grafana_data_source.this
  id = "Xkab8qYIz"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.xray_source["analytical-platform-ingestion-development"].grafana_data_source.this
  id = "ANZKPz1Iz"
}

import {
  to = module.tenant_configuration["observability-platform"].module.xray_source["observability-platform-development"].grafana_data_source.this
  id = "azpsSr5Iz"
}
