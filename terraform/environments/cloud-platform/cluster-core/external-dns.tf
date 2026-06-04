module "external_dns" {
  source = "github.com/ministryofjustice/container-platform-terraform-external-dns?ref=0.1.0"
  
  eks_cluster_name = local.cluster_name

  required_inputs = {
    cloud-platform-development = {
      version                 = var.chart_version
      domain_name_prefix      = "development"
      sync_interval           = var.sync_interval.development
      aws_zone_cache_duration = var.aws_zone_cache_duration.development
      log_level               = "info"
    }
  }
  tags = var.tags
}