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
  #     Default: local.custom_idp_configuration.ingress_cidr_blocks
  #     (the shared ingress allow-list for the transfer server).
  #
  #   home_directory_target (string)
  #     The physical S3 path the user's logical "/" maps to. The transfer
  #     server uses LOGICAL home directories, so this is an S3 location of the
  #     form "/<bucket>/<prefix>", not a server-wide setting. Point it at the
  #     bucket/prefix the user should land in (the unscanned bucket is the AV
  #     scan landing zone).
  #     Default: "/<unscanned-bucket>/<username>"
  #
  # Example of a fully specified user, overriding every default (uncomment and
  # adapt as needed):
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
