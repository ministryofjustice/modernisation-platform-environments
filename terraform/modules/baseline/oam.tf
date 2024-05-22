# OAM = AWS CloudWatch Observability Access Manager
# Create a link in the account which sends metrics
# Create a sink in the account which receive metrics

resource "aws_oam_link" "this" {
  for_each = var.oam_links

  label_template  = each.key
  resource_types  = each.value.resource_types
  sink_identifier = aws_ssm_parameter.placeholder[each.value.sink_identifier_ssm_parameter_name].value

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_oam_sink" "this" {
  for_each = var.oam_sinks

  name = each.key
  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_oam_sink_policy" "monitoring_account_oam_sink_policy" {
  for_each = var.oam_sinks

  sink_identifier = aws_oam_sink.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["oam:CreateLink", "oam:UpdateLink"]
        Effect   = "Allow"
        Resource = "*"
        Principal = {
          "AWS" = [for name in each.value.source_account_names : var.environment.account_ids[name]]
        }
        Condition = {
          "ForAllValues:StringEquals" = {
            "oam:ResourceTypes" = each.value.resource_types
          }
        }
      }
    ]
  })
}
