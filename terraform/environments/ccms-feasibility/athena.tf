# Athena over the shared load balancer access logs bucket (s3.tf).
#
# Tables alb_access_logs and nlb_access_logs are partitioned by lb (the load balancer's directory) and day (yyyy/MM/dd):
#   SELECT * FROM alb_access_logs WHERE lb = 'ccms-pui' AND day = '2026/09/29' LIMIT 100;

module "athena" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/7ecf91e
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/athena?ref=7ecf91e"

  name             = local.application_name
  bucket_name      = module.s3_lb_access_logs.bucket.id
  alb_log_prefixes = local.alb_access_log_prefixes
  nlb_log_prefixes = local.nlb_access_log_prefixes

  tags = local.tags
}
