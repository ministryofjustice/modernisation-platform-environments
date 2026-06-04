module "starter_pack_ecr" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=8.0.1"
  count  = local.environment == "development" ? 1 : 0

  repo_name = "container-platform-terraform-starter-pack"

  # OpenID Connect configuration
  oidc_providers      = ["github"]
  github_repositories = ["container-platform-terraform-starter-pack"]

  # Tags
  business_unit          = "OCTO"
  application            = local.application_name
  is_production          = local.is-production
  team_name              = "cloud-platform"
  namespace              = "container-platform-terraform-starter-pack"
  environment_name       = local.environment
  infrastructure_support = "platforms@digital.justice.gov.uk"
}

