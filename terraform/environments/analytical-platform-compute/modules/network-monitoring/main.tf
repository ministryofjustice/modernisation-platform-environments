resource "aws_networkmonitor_monitor" "this" {
  monitor_name       = var.monitor_name
  aggregation_period = var.aggregation_period

  tags = var.tags
}

resource "aws_networkmonitor_probe" "this" {
  for_each = toset(var.source_arns)

  monitor_name     = aws_networkmonitor_monitor.this.monitor_name
  destination      = var.destination
  destination_port = var.destination_port
  protocol         = var.protocol
  packet_size      = var.packet_size
  source_arn       = each.value

  tags = var.tags
}
