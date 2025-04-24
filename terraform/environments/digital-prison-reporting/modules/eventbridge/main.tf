
resource "aws_cloudwatch_event_bus" "this" {
  name = var.dpr_event_bus_name

  tags = var.tags
}
