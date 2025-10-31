# OAM = AWS CloudWatch Observability Access Manager
# Create a link in the account which sends metrics
# Create a sink in the account which receive metrics
#
# STEP 1.
# First create a sink in the account that will receive metrics.
# Set `source_account_names` to the list of accounts to give permissions to
#   oam_sinks = {
#     "CloudWatchMetricOamSink" = {
#       resource_types = ["AWS::CloudWatch::Metric"]
#       source_account_names = [
#         "corporate-staff-rostering-${local.environment}",
#         "hmpps-domain-services-${local.environment}",
#         "nomis-${local.environment}",
#       ]
#     }
#   }
#
# STEP 2.
# Create a placeholder SSM parameter in the account which sends metrics containing the sink id.
# Use the baseline_presets module `cloudwatch_metric_oam_links_ssm_parameters` option.
# For example:
#   cloudwatch_metric_oam_links_ssm_parameters = ["hmpps-oem-${local.environment}"]
# to create an /oam/hmpps-oem-${local.environment} ssm parameter
#
# STEP 3.
# Populate SSM parameter with the sink identifier
#   environment=development
#   application=nomis
#   arn=$(aws oam list-sinks --profile "hmpps-oem-$environment" | jq -r '.Items[] | select(.Name=="CloudWatchMetricOamSink").Arn')
#   aws ssm put-parameter --name "/oam/hmpps-oem-$environment" --type "SecureString" --data-type "text" --value "$arn" --profile "$application-$environment" --overwrite
#
# STEP 4.
# Create the oam link and policy in the account which sends metrics.
# Use the baseline_presets module `cloudwatch_metric_oam_links` option.
# For example:
#   cloudwatch_metric_oam_links = ["hmpps-oem-${local.environment}"]
# to create required eam_links and iam_roles

resource "aws_oam_link" "this" {
  for_each = var.oam_links

  label_template  = each.value.label_template
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
