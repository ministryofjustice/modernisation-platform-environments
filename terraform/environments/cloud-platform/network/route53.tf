## Only create Route53 zone in development clusters

resource "aws_route53_zone" "cluster_zone" {
  count         = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  name          = "${local.environment_configuration.route53_prefix}.${local.environment_configuration.account_hosted_zone}"
  force_destroy = true

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_record" "cluster_hosted_zone_ns" {
  count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  zone_id = data.aws_route53_zone.account_hosted_zone.zone_id
  name    = aws_route53_zone.cluster_zone[0].name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.cluster_zone[0].name_servers[0],
    aws_route53_zone.cluster_zone[0].name_servers[1],
    aws_route53_zone.cluster_zone[0].name_servers[2],
    aws_route53_zone.cluster_zone[0].name_servers[3],
  ]

  depends_on = [aws_route53_zone.cluster_zone]
}
