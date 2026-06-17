# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  deploy_to         = ["development"]
  
  geofence_app = {
    jar_filename   = "flink-moj-geofence-1.0.jar"
    jar_local_path = "/tmp/flink-moj-geofence-1.0.jar"
  }
  
  rules_app = {
    jar_filename   = "flink-rules-1.0.jar"
    jar_local_path = "/tmp/flink-rules-1.0.jar"
  }
}
