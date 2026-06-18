# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name      = "streaming-poc-maf"
  deploy_to = ["development"]

  geofence_app = {
    jar_filename = "flink-moj-geofence-1.0.0.jar"
  }

  rules_app = {
    jar_filename = "flink-rules-1.0.0.jar"
  }

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
