locals {
  #if envinment is dev set to dev, prod set to prod, preprod set to preprod
  datadog_integration_external_id = {
    "prod"        = ""
    "preprod"     = ""
    "development" = "a43e2b2de71041889dbb5d2cd8170356"
    "test"        = ""
  }
}

#todo remove this
import {
  to = module.datadog.aws_iam_role.datadog_aws_integration
  id = "DatadogAWSIntegrationRole"
}
#todo remove this
import {
  to = module.datadog.aws_iam_policy.datadog_aws_integration
  id = "arn:aws:iam::225989353474:policy/DatadogAWSIntegrationPolicy"
}


module "datadog" {
  source                          = "./modules/datadog"
  project_name                    = local.project_name
  datadog_integration_external_id = local.datadog_integration_external_id[local.environment]
  tags                            = local.tags
}
