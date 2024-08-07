resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = var.app_load_balancer.arn
  web_acl_arn  = var.waf_arn
}