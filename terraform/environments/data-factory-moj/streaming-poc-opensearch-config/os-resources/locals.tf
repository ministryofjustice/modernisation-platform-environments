locals {
  saved_objects = fileset("${path.cwd}/saved-objects", "*.ndjson")
  os_creds      = jsondecode(data.aws_secretsmanager_secret_version.opensearch_credentials.secret_string)
  region        = "eu-west-2"

  opensearch_role_mappings = {
    "all_access" = {
      backend_roles = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-moj-geofence-flink-iam-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-rules-flink-iam-role"
      ]
      users = ["${local.os_creds.username}"]
    }
  }
}
