module "route53_resolver_moj_blocklist_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "route53-resolver/moj-blocklist"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}
