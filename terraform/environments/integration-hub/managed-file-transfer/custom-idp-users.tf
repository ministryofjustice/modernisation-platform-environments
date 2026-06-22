locals {
  # Custom IdP user records. Add a new user by appending a key to this map; every
  # field is optional and falls back to a sensible default in the
  # aws_dynamodb_table_item.custom_idp_user resource (see custom-idp-dynamodb.tf).
  #
  # Defaults applied when a field is omitted:
  #   identity_provider_key = "secrets"
  #   ipv4_allow_list       = local.custom_idp_configuration.ingress_cidr_blocks
  #   home_directory_target = "/<unscanned-bucket>/<username>"
  #
  # Example of a fully specified user (uncomment and adapt as needed):
  #
  # alice = {
  #   identity_provider_key = "secrets"
  #   ipv4_allow_list       = ["203.0.113.0/24", "198.51.100.10/32"]
  #   home_directory_target = "/${module.s3_bucket["unscanned"].s3_bucket_id}/alice"
  # }
  custom_idp_users = {
    dms1981 = {}
  }
}
