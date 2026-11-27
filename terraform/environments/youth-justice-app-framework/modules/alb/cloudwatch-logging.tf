resource "aws_cloudwatch_log_group" "alb" {
  for_each = var.enable_cloudwatch_logs ? toset(var.cloudwatch_log_types) : toset([])

  name              = "/aws/elasticloadbalancing/${var.alb_name}-${local.alb_suffix}/${lower(each.value)}"
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = var.cloudwatch_log_kms_key_arn
  tags              = local.all_tags
}

resource "aws_cloudwatch_log_delivery_source" "alb" {
  for_each = aws_cloudwatch_log_group.alb

  name         = "${var.alb_name}-${local.alb_suffix}-${replace(lower(each.key), "_", "-")}"
  log_type     = each.key
  resource_arn = module.alb.arn
  tags         = local.all_tags
}

resource "aws_cloudwatch_log_delivery_destination" "alb" {
  for_each = aws_cloudwatch_log_group.alb

  name          = "${var.alb_name}-${local.alb_suffix}-${replace(lower(each.key), "_", "-")}"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = each.value.arn
  }

  tags = local.all_tags
}

resource "aws_cloudwatch_log_delivery" "alb" {
  for_each = aws_cloudwatch_log_group.alb

  delivery_source_name     = aws_cloudwatch_log_delivery_source.alb[each.key].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.alb[each.key].arn
  tags                     = local.all_tags
}
