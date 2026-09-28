# Justice Data Platform (AWS ProServe): pipeline smoke test.
#
# Purpose: prove the plan / review / apply path through this repository for the
# JDP delivery team, without touching any existing component or resource.
# Creates a single SSM parameter in the development account only. Safe to delete
# once the first JDP component lands.

resource "aws_ssm_parameter" "jdp_pipeline_smoke_test" {
  count = local.environment == "development" ? 1 : 0

  name        = "/jdp/pipeline-smoke-test"
  description = "Justice Data Platform: first change deployed via modernisation-platform-environments"
  type        = "SecureString" # Checkov CKV2_AWS_34; default aws/ssm key, no new resources
  value       = "ok"
  tier        = "Standard"
}
