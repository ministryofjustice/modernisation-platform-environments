module "external_dns" {
  source = "github.com/ministryofjustice/container-platform-terraform-external-dns?ref=update-for-gatewayapi"

  eks_cluster_name = local.cluster_name

  required_inputs = {
    cloud-platform-development = {
      version                 = "1.21.1"
      domain_name_prefix      = "development"
      sync_interval           = "10m"
      aws_zone_cache_duration = "2h"
      log_level               = "debug"
    }
  }
  tags = {
    application   = "External DNS"
    business-unit = "OCTO"
    owner         = "Container Platform: External DNS"
    service-area  = "Hosting"
    source-code   = "https://github.com/ministryofjustice/cloud-platform-external-dns"
    slack-channel = "cloud-platform"
    is-production = "true"
  }
}