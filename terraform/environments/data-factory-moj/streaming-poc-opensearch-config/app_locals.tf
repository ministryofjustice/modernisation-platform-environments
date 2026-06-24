locals {
  all_vars      = jsondecode(file("${path.cwd}/../application_variables.json"))
  os_mappings   = try(local.all_vars.accounts[local.environment].opensearch_role_mappings, {})
  saved_objects = fileset("${path.cwd}/saved-objects", "*.ndjson")
  os_creds      = jsondecode(data.aws_secretsmanager_secret_version.opensearch_credentials.secret_string)
  region        = "eu-west-2"
  extended_tags = merge(local.tags, {})

  escaped_payloads = {
    for role_name, mapping_data in local.os_mappings : role_name => replace(replace(replace(
      jsonencode({
        backend_roles = mapping_data["backend_roles"]
        users         = mapping_data["users"]
      }),
      "\"",
      "\\\\\\\""
    ), "ACCOUNT_ID", data.aws_caller_identity.current.account_id), "USER", local.os_creds.username)
  }

  geo_fence_events_b64 = base64encode(
    file("${path.cwd}/index/geo-fence-events.json")
  )
}
