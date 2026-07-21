locals {
  sync_interval = {
    development = "10m"
    production  = "60m"
  }
  aws_zone_cache_duration = {
    development = "2h"
    production  = "2h"
  }
}

module "external_dns" {
  source = "github.com/ministryofjustice/container-platform-terraform-external-dns?ref=1eb83cb5fe74482ca4dc2caad313a53c0e7a4e6b" #1.1.0

  eks_cluster_name = local.cluster_name

  required_inputs = {
    cloud-platform-development = {
      domain_name_prefix      = "development"
      sync_interval           = local.sync_interval.development
      aws_zone_cache_duration = local.aws_zone_cache_duration.development
      log_level               = "info"
    }
    cloud-platform-preproduction = {
      domain_name_prefix      = "preproduction"
      sync_interval           = local.sync_interval.development
      aws_zone_cache_duration = local.aws_zone_cache_duration.development
      log_level               = "info"
    }
    cloud-platform-live = {
      domain_name_prefix      = "live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-octo-nonlive = {
      domain_name_prefix      = "octo-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-octo-live = {
      domain_name_prefix      = "octo-live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-laa-nonlive = {
      domain_name_prefix      = "laa-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-laa-live = {
      domain_name_prefix      = "laa-live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-hmpps-nonlive = {
      domain_name_prefix      = "hmpps-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-hmpps-live = {
      domain_name_prefix      = "hmpps-live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
  }
  tags = {
    application   = "External DNS"
    business-unit = "OCTO"
    owner         = "Container Platform: External DNS"
    service-area  = "Hosting"
    source-code   = "https://github.com/ministryofjustice/container-platform-terraform-external-dns"
    slack-channel = "cloud-platform"
    is-production = "true"
  }
}
