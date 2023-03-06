output "app_lb_route53_record" {
  description = "App LB Route53 record"
  value       = aws_route53_record.route53_record_app_lb.fqdn
}

output "db_route53_record" {
  description = "DB Route53 record"
  value       = aws_route53_record.route53_record_db.fqdn
}
