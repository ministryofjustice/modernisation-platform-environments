resource "aws_route53_zone" "cluster_zone" {
  name = trimprefix(terraform.workspace, "cloud-platform-") + ".cloud-platform.service.justice.gov.uk"
  force_destroy = true

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.aws_route53_zone.shared_parent_zone.zone_id
  name    = aws_route53_zone.cluster_zone.name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.cluster_zone.name_servers[0],
    aws_route53_zone.cluster_zone.name_servers[1],
    aws_route53_zone.cluster_zone.name_servers[2],
    aws_route53_zone.cluster_zone.name_servers[3],
  ]
}