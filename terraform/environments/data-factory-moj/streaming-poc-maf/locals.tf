# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  deploy_to = ["development"]
  msk_arn   = data.external.msk_arn.result.arn == "None" ? "*" : data.external.msk_arn.result.arn
  geofence_app = {
    jar_filename = "flink-moj-geofence-1.0.0.jar"
  }

  rules_app = {
    jar_filename = "flink-rules-1.0.0.jar"
  }
}
