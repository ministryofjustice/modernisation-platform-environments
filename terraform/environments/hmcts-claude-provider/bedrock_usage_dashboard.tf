locals {
  # USD per million tokens, Anthropic list price x1.1 for the EU regional endpoint premium.
  # Bedrock is partner-priced, so treat the dashboard totals as an estimate, not an invoice.
  # Rates are matched against modelId by substring: "opus-5" also matches "opus-5-5", so the
  # 5.5 hit is subtracted back out. Models sharing a rate (opus-5/4.8, sonnet-5/5.5) share a match.
  bedrock_cost_fields = <<-QUERY
    | fields coalesce(requestMetadata.user, identity.arn) as user
    | fields strcontains(modelId, "opus-5-5") as m_opus55,
             strcontains(modelId, "opus-5") as m_opus5_any,
             strcontains(modelId, "opus-4-8") as m_opus48,
             strcontains(modelId, "sonnet-5") as m_sonnet5,
             strcontains(modelId, "sonnet-4-6") as m_sonnet46,
             strcontains(modelId, "haiku-4-5") as m_haiku45,
             strcontains(modelId, "fable-5") as m_fable5
    | fields m_opus5_any - m_opus55 as m_opus5
    | fields m_opus55 * 4.4 + m_opus5 * 5.5 + m_opus48 * 5.5 + m_sonnet5 * 2.2 + m_sonnet46 * 3.3 + m_haiku45 * 1.1 + m_fable5 * 11 as r_in,
             m_opus55 * 5.5 + m_opus5 * 6.875 + m_opus48 * 6.875 + m_sonnet5 * 2.75 + m_sonnet46 * 4.125 + m_haiku45 * 1.375 + m_fable5 * 13.75 as r_cw,
             m_opus55 * 0.22 + m_opus5 * 0.55 + m_opus48 * 0.55 + m_sonnet5 * 0.22 + m_sonnet46 * 0.33 + m_haiku45 * 0.11 + m_fable5 * 1.1 as r_cr,
             m_opus55 * 22 + m_opus5 * 27.5 + m_opus48 * 27.5 + m_sonnet5 * 11 + m_sonnet46 * 16.5 + m_haiku45 * 5.5 + m_fable5 * 55 as r_out
    | fields input.inputTokenCount * r_in as c_in,
             input.cacheWriteInputTokenCount * r_cw as c_cw,
             input.cacheReadInputTokenCount * r_cr as c_cr,
             output.outputTokenCount * r_out as c_out
  QUERY
}

resource "aws_cloudwatch_dashboard" "bedrock_usage" {
  region         = local.bedrock_logging_region
  dashboard_name = "hmcts-claude-bedrock-usage"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          markdown = <<-MD
            ## Claude on Bedrock: usage and estimated cost

            Sourced from Bedrock model invocation logs in ${local.bedrock_logging_region}, retained for ${local.bedrock_log_retention_days} days.

            **User** is the `user` field Claude Code sends in request metadata, falling back to the IAM principal for keys that send none —
            those rows are shared `BedrockAPIKey-*` pool keys, so they attribute to a key rather than a person.
            **Costs are estimates**: Anthropic list prices plus the 10% EU regional endpoint premium, not Bedrock's own rate card. Reconcile against the bill before charging anyone.
          MD
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 3
        width  = 24
        height = 9
        properties = {
          region = local.bedrock_logging_region
          title  = "Tokens by user (30 days)"
          view   = "table"
          start  = "-P30D"
          query  = join("\n", [
            "SOURCE '${aws_cloudwatch_log_group.bedrock_logs.name}'",
            "| fields coalesce(requestMetadata.user, identity.arn) as user, requestMetadata.team as team",
            "| stats count(*) as calls, sum(input.inputTokenCount) as input_tokens, sum(input.cacheReadInputTokenCount) as cache_read, sum(input.cacheWriteInputTokenCount) as cache_write, sum(output.outputTokenCount) as output_tokens by user, team",
            "| sort calls desc",
          ])
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 9
        properties = {
          region = local.bedrock_logging_region
          title  = "Estimated cost by user, USD (30 days)"
          view   = "table"
          start  = "-P30D"
          query  = join("\n", [
            "SOURCE '${aws_cloudwatch_log_group.bedrock_logs.name}'",
            trimspace(local.bedrock_cost_fields),
            "| stats (sum(c_in) + sum(c_cw) + sum(c_cr) + sum(c_out)) / 1000000 as est_usd, count(*) as calls by user",
            "| sort est_usd desc",
          ])
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 12
        width  = 12
        height = 9
        properties = {
          region = local.bedrock_logging_region
          title  = "Estimated cost by model, USD (30 days)"
          view   = "table"
          start  = "-P30D"
          query  = join("\n", [
            "SOURCE '${aws_cloudwatch_log_group.bedrock_logs.name}'",
            trimspace(local.bedrock_cost_fields),
            "| stats (sum(c_in) + sum(c_cw) + sum(c_cr) + sum(c_out)) / 1000000 as est_usd, count(*) as calls by modelId",
            "| sort est_usd desc",
          ])
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 21
        width  = 24
        height = 7
        properties = {
          region = local.bedrock_logging_region
          title  = "Estimated daily cost by user, USD (14 days)"
          view   = "bar"
          start  = "-P14D"
          query  = join("\n", [
            "SOURCE '${aws_cloudwatch_log_group.bedrock_logs.name}'",
            trimspace(local.bedrock_cost_fields),
            "| stats (sum(c_in) + sum(c_cw) + sum(c_cr) + sum(c_out)) / 1000000 as est_usd by bin(1d), user",
          ])
        }
      },
    ]
  })
}
