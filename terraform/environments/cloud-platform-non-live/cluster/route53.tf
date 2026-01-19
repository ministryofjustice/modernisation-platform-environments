## Only create Route53 zone in development clusters

resource "aws_route53_zone" "development_cluster_zone" {
  count = contains(locals.mp_environments, terraform.workspace) ? 0 : 1
  
  name = terraform.workspace + ".temp.cloud-platform.service.justice.gov.uk"
  force_destroy = true

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_record" "development_hosted_zone_ns" {
  count = contains(locals.mp_environments, terraform.workspace) ? 0 : 1
  
  zone_id = data.aws_route53_zone.development_hosted_zone.zone_id
  name    = aws_route53_zone.development_cluster_zone[0].name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.development_cluster_zone[0].name_servers[0],
    aws_route53_zone.development_cluster_zone[0].name_servers[1],
    aws_route53_zone.development_cluster_zone[0].name_servers[2],
    aws_route53_zone.development_cluster_zone[0].name_servers[3],
  ]
}