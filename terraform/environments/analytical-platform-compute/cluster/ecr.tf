module "ecr" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  create_repository = false

  registry_pull_through_cache_rules = {
    ecr = {
      ecr_repository_prefix = "ecr"
      upstream_registry_url = "public.ecr.aws"
    }
    ghcr = {
      ecr_repository_prefix = "github"
      upstream_registry_url = "ghcr.io"
      credential_arn        = module.ecr_github_pull_through_cache_secret.secret_arn
    }
  }

  tags = local.tags
}
