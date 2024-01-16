output "ldap_aws_lb_id" {
    value = aws_lb.ldap.dns_name
}