module "ecr" {
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
