locals {
  # Custom IdP user records. Add a new user by appending a key (the username) to
  # this map. Every field is optional: an empty object (e.g. `dms1981 = {}`)
  # creates a fully working user on all defaults. Each field is resolved with a
  # try() fallback in aws_dynamodb_table_item.custom_idp_user (see
  # custom-idp-dynamodb.tf).
  #
  # Field reference and default applied when omitted:
  #
  #   identity_provider_key (string)
  #     Which identity provider record authenticates the user.
  #     Default: "secrets" (authenticate against AWS Secrets Manager).
  #
  #   ipv4_allow_list (list(string))
  #     Source CIDR blocks permitted to authenticate as this user.
  #     Default: local.custom_idp_configuration.ingress_cidr_blocks, defined in
  #     application_variables.json as the shared ingress allow-list for the
  #     transfer server.
  #
  #   home_directory_target (string)
  #     The user-relative prefix inside the unscanned bucket that the user's
  #     logical "/" maps to. The unscanned bucket is always used as the root.
  #     Default: "<username>"
  #
  # Example of a fully specified user, overriding every default (uncomment and
  # adapt as needed):
  #
  # alice = {
  #   home_directory_target = "alice"
  #   identity_provider_key = "secrets"
  #   ipv4_allow_list       = ["203.0.113.0/24", "198.51.100.10/32"]
  # }
  custom_idp_users = {
    dms1981 = {}
  }
}
