resource "aws_lb" "tribunals_lb" {
  name               = "tribunals-lb"
  load_balancer_type = "application"
  security_groups = [
    module.appeals.tribunals_lb_sc_id,
    module.ahmlr.tribunals_lb_sc_id,
    module.care_standards.tribunals_lb_sc_id,
    module.cicap.tribunals_lb_sc_id,
    module.employment_appeals.tribunals_lb_sc_id,
    module.finance_and_tax.tribunals_lb_sc_id,
    module.immigration_services.tribunals_lb_sc_id,
    module.information_tribunal.tribunals_lb_sc_id,
    module.lands_tribunal.tribunals_lb_sc_id,
    module.transport.tribunals_lb_sc_id,
    module.charity_tribunal_decisions.tribunals_lb_sc_id,
    module.claims_management_decisions.tribunals_lb_sc_id,
    module.consumer_credit_appeals.tribunals_lb_sc_id,
    module.estate_agent_appeals.tribunals_lb_sc_id,
    module.primary_health_lists.tribunals_lb_sc_id,
    module.siac.tribunals_lb_sc_id,
    module.sscs_venue_pages.tribunals_lb_sc_id,
    module.tax_chancery_decisions.tribunals_lb_sc_id,
    module.tax_tribunal_decisions.tribunals_lb_sc_id,
    module.ftp_admin_appeals.tribunals_lb_sc_id
  ]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
}
