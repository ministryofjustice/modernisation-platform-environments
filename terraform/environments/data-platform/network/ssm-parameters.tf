resource "aws_ssm_parameter" "network_monitor_scope_arn" {
  #checkov:skip=CKV2_AWS_34: "AWS SSM Parameter should be Encrypted"
  name  = "/cloudwatch/network-monitor/scope-arn"
  type  = "String"
  value = aws_networkflowmonitor_scope.main.scope_arn
}
