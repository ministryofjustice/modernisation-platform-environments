#checkov:skip=CKV2_AWS_34: Stores a non-sensitive scope ARN string; KMS encryption is not required for this parameter.
resource "aws_ssm_parameter" "network_monitor_scope_arn" {
  name  = "/cloudwatch/network-monitor/scope-arn"
  type  = "String"
  value = aws_networkflowmonitor_scope.main.scope_arn
}
