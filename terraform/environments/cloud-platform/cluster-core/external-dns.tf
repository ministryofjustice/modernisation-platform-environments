locals {
  chart_version = "1.21.1"
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
  source = "github.com/ministryofjustice/container-platform-terraform-external-dns?ref=0.0.1"

  eks_cluster_name = local.cluster_name

  required_inputs = {
    cloud-platform-development = {
      version                 = local.chart_version
      domain_name_prefix      = "development"
      sync_interval           = local.sync_interval.development
      aws_zone_cache_duration = local.aws_zone_cache_duration.development
      log_level               = "info"
    }
    cloud-platform-preproduction = {
      version                 = local.chart_version
      domain_name_prefix      = "preproduction"
      sync_interval           = local.sync_interval.development
      aws_zone_cache_duration = local.aws_zone_cache_duration.development
      log_level               = "info"
    }
    cloud-platform-live = {
      version                 = local.chart_version
      domain_name_prefix      = "live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-octo-nonlive = {
      version                 = local.chart_version
      domain_name_prefix      = "octo-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-octo-live = {
      version                 = local.chart_version
      domain_name_prefix      = "octo-live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-laa-nonlive = {
      version                 = local.chart_version
      domain_name_prefix      = "laa-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-laa-live = {
      version                 = local.chart_version
      domain_name_prefix      = "laa-live"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-hmpps-nonlive = {
      version                 = local.chart_version
      domain_name_prefix      = "hmpps-nonlive"
      sync_interval           = local.sync_interval.production
      aws_zone_cache_duration = local.aws_zone_cache_duration.production
      log_level               = "info"
    }
    container-platform-hmpps-live = {
      version                 = local.chart_version
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
