resource "aws_ssm_parameter" "cortex_account_id" {
  #checkov:skip=CKV2_AWS_34: "Parameter is not sensitive; account ID is publicly available."
  count = local.create_resources ? 1 : 0
  lifecycle {
    ignore_changes = [insecure_value]
  }
  description    = "Account ID for Palo Alto Cortex XSIAM cross-account role."
  name           = "cortex_account_id"
  type           = "String"
  insecure_value = "006742885340"
  tags           = local.tags
}