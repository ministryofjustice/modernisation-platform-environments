locals {
  deploy_to = ["development"]
  extended_tags = merge(local.tags, {
    component = "streaming-pov-opensearch-config"
  })
  all_vars      = jsondecode(file("${path.cwd}/../application_variables.json"))
  os_mappings   = try(local.all_vars.accounts[local.environment].opensearch_role_mappings, {})
  saved_objects = fileset("${path.cwd}/saved-objects", "*.ndjson")
  os_creds      = jsondecode(data.aws_secretsmanager_secret_version.opensearch_credentials.secret_string)
  region        = "eu-west-2"
  extended_tags = merge(local.tags, {})

#   opensearch_role_mappings = {
#     "all_access" = {
#       backend_roles = [
#         "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-moj-geofence-flink-iam-role",
#         "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-rules-flink-iam-role"
#       ]
#       users = ["${local.os_creds.username}"]
#     }
#   }



    escaped_payloads = {
        for role_name, mapping_data in local.os_mappings : role_name => replace(replace(replace(
        jsonencode({
            backend_roles = mapping_data["backend_roles"]
            users         = mapping_data["users"]
        }),
        "\"",
        "\\\\\\\""
        ), "ACCOUNT_ID", data.aws_caller_identity.current.account_id), "USER", local.region)
    }

  #   geo_fence_events_b64 = base64encode(
  #     file("${path.cwd}/index/geo-fence-events.json")
  #   )
}
