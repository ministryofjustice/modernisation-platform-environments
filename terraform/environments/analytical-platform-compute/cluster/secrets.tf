module "ecr_github_pull_through_cache_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name        = "ecr-pullthroughcache/github"
  description = "GitHub credentials for ECR pull-through cache"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}
