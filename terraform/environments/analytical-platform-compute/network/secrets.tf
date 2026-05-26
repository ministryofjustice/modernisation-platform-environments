module "route53_resolver_moj_blocklist_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=85977d132b8491281266ca412cee3e9ce7f2b457" # v1.3.1

  name = "route53-resolver/moj-blocklist"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}
