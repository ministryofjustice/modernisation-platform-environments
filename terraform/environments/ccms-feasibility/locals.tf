#### This file can be used to store locals specific to the member account ####

locals {
  # Shared bucket for access logs from every feasibility load balancer.
  lb_access_logs_bucket_name = "${local.application_name}-${local.environment}-lb-access-logs"

  # One directory per load balancer.
  alb_access_log_prefixes = [
    "ccms-ebs-${local.env_label}",       # ccms-ebs/ebsapps-alb.tf
    "ccms-edrms-${local.env_label}",     # ccms-edrms/alb.tf
    "ccms-opahub-${local.env_label}",    # ccms-oia/alb.tf
    "ccms-connector-${local.env_label}", # ccms-oia/alb.tf
    "ccms-adaptor-${local.env_label}",   # ccms-oia/alb.tf
    "ccms-pui-${local.env_label}",       # ccms-pui/alb.tf
  ]

  # NLBs only write access logs for TLS listeners
  nlb_access_log_prefixes = [
    "ccms-soa-admin-${local.env_label}",   # ccms-soa/nlb.tf
    "ccms-soa-managed-${local.env_label}", # ccms-soa/nlb.tf
  ]
}
