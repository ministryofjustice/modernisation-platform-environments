#### This file can be used to store locals specific to the member account ####

locals {
  # Shared bucket for access logs from every feasibility load balancer.
  lb_access_logs_bucket_name = "${local.application_name}-lb-access-logs"

  # One directory per load balancer.
  alb_access_log_prefixes = [
    "ccms-ebs",       # ccms-ebs/ebsapps-alb.tf
    "ccms-edrms",     # ccms-edrms/alb.tf
    "ccms-opahub",    # ccms-oia/alb.tf
    "ccms-connector", # ccms-oia/alb.tf
    "ccms-adaptor",   # ccms-oia/alb.tf
    "ccms-pui",       # ccms-pui/alb.tf
  ]

  # NLBs only write access logs for TLS listeners
  nlb_access_log_prefixes = [
    "ccms-soa-admin",   # ccms-soa/nlb.tf
    "ccms-soa-managed", # ccms-soa/nlb.tf
  ]
}
