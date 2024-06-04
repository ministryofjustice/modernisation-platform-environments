module "shield" {
  source = "../../modules/shield_advanced"
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  monitored_resources = {
    public_lb      = aws_lb.external.arn,
    certificate_lb = aws_lb.certificate_example_lb.arn
  }
}
