#Add route53 record for external access to ALB
resource "aws_route53_record" "dns" {
  zone_id = var.r53_zone_id
  name    = var.tableau_website_name
  type    = "CNAME"
  ttl     = 300
  records = [module.tableau-alb.dns_name]
}
