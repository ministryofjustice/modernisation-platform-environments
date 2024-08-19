/*
This file is temporary and will be removed once imports are done in production
Working from this plan https://github.com/ministryofjustice/modernisation-platform-environments/actions/runs/10373629467/job/28799856877?pr=7439
*/

import {
  to = grafana_data_source.github
  id = "bkklZqJSk"
}

import {
  to = grafana_data_source.observability_platform_prometheus
  id = "b0LdomDIk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.amazon_prometheus_query_source["analytical-platform-compute-production"].grafana_data_source.this
  id = "jCTSdHsSk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.cloudwatch_source["analytical-platform-compute-production"].grafana_data_source.this
  id = "rKHiQ3LSk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.cloudwatch_source["analytical-platform-ingestion-production"].grafana_data_source.this
  id = "Vw2Vsz1Iz"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.xray_source["analytical-platform-compute-production"].grafana_data_source.this
  id = "j9Ziw3LIk"
}

import {
  to = module.tenant_configuration["analytical-platform"].module.xray_source["analytical-platform-ingestion-production"].grafana_data_source.this
  id = "Y4c4skJSk"
}

import {
  to = module.tenant_configuration["modernisation-platform"].module.cloudwatch_source["core-logging-production"].grafana_data_source.this
  id = "zAGNE2lSk"
}

import {
  to = module.tenant_configuration["modernisation-platform"].module.cloudwatch_source["core-network-services-production"].grafana_data_source.this
  id = "8ArgVsySk"
}

import {
  to = module.tenant_configuration["modernisation-platform"].module.cloudwatch_source["core-security-production"].grafana_data_source.this
  id = "veWNEh_Sz"
}

import {
  to = module.tenant_configuration["modernisation-platform"].module.cloudwatch_source["core-shared-services-production"].grafana_data_source.this
  id = "HzGHE2lSz"
}

import {
  to = module.tenant_configuration["modernisation-platform"].module.cloudwatch_source["core-vpc-production"].grafana_data_source.this
  id = "RAMNE2_Ik"
}

import {
  to = module.tenant_configuration["observability-platform"].module.cloudwatch_source["observability-platform-production"].grafana_data_source.this
  id = "j5q0EC5Sz"
}

import {
  to = module.tenant_configuration["observability-platform"].module.xray_source["observability-platform-production"].grafana_data_source.this
  id = "jhl0PjcSk"
}
