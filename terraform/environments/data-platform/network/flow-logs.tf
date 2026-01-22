resource "aws_flow_log" "vpc" {
  iam_role_arn    = module.vpc_flow_logs_iam_role.arn
  log_destination = module.vpc_flow_logs_log_group.cloudwatch_log_group_arn
  traffic_type    = "ALL"
  log_format      = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-cloudwatch-logs"
  }
}
