# TEMPORARY: lets the management server call yjsm-hub through the yjsm apps NLB
# in test, to find out whether the NLB is why large replies stall. Delete this
# file once that test is done.
locals {
  yjsm_nlb_mgmt_test_count = local.environment == "test" ? 1 : 0
  yjsm_hub_listener_port   = local.yjsm_juniper_facing_apps["yjsm-hub"].port
}

resource "aws_security_group_rule" "mgmt_to_yjsm_apps_nlb_test" {
  count                    = local.yjsm_nlb_mgmt_test_count
  type                     = "ingress"
  from_port                = local.yjsm_hub_listener_port
  to_port                  = local.yjsm_hub_listener_port
  protocol                 = "tcp"
  security_group_id        = module.yjsm_apps_nlb.nlb_security_group_id
  source_security_group_id = module.ds.management_server_sg_id
  description              = "TEMPORARY management server to yjsm apps NLB"
}

# The NLB preserves the client IP, so the ALB sees the management server as the source.
resource "aws_security_group_rule" "mgmt_to_yjsm_apps_alb_hub_test" {
  count                    = local.yjsm_nlb_mgmt_test_count
  type                     = "ingress"
  from_port                = local.yjsm_hub_listener_port
  to_port                  = local.yjsm_hub_listener_port
  protocol                 = "tcp"
  security_group_id        = module.yjsm_apps_alb.alb_security_group_id
  source_security_group_id = module.ds.management_server_sg_id
  description              = "TEMPORARY management server to yjsm-hub on the yjsm apps ALB"
}

resource "aws_security_group_rule" "mgmt_to_yjsm_apps_nlb_test_egress" {
  count                    = local.yjsm_nlb_mgmt_test_count
  type                     = "egress"
  from_port                = local.yjsm_hub_listener_port
  to_port                  = local.yjsm_hub_listener_port
  protocol                 = "tcp"
  security_group_id        = module.ds.management_server_sg_id
  source_security_group_id = module.yjsm_apps_nlb.nlb_security_group_id
  description              = "TEMPORARY management server to yjsm apps NLB"
}
