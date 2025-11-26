resource "aws_cloudwatch_dashboard" "workspacesweb_active_sessions" {
  count          = local.create_resources ? 1 : 0
  dashboard_name = "workspacesweb-active-sessions"

  dashboard_body = jsonencode({
    periodOverride = "inherit"

    widgets = [
      {
        "type" = "metric",
        "x"    = 0, "y" = 0, "width" = 18, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Active Sessions — per five minutes",
          "view"     = "timeSeries",
          "stacked"  = false,
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 300,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "ActiveSession (sum)",
                "expression" = "SELECT SUM(ActiveSession) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
      {
        "type" = "metric",
        "x"    = 18, "y" = 0, "width" = 6, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Active Sessions — last five minutes",
          "view"     = "singleValue",
          "stacked"  = false,
          "start"    = "-PT5M",
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 300,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "ActiveSession (sum)",
                "expression" = "SELECT SUM(ActiveSession) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
      {
        "type" = "metric",
        "x"    = 0, "y" = 6, "width" = 18, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Active Sessions — last hour",
          "view"     = "timeSeries",
          "stacked"  = false,
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 3600,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "ActiveSession (sum)",
                "expression" = "SELECT SUM(ActiveSession) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
      {
        "type" = "metric",
        "x"    = 18, "y" = 6, "width" = 6, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Active Sessions — last hour",
          "view"     = "singleValue",
          "stacked"  = false,
          "start"    = "-PT1H",
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 3600,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "ActiveSession (sum)",
                "expression" = "SELECT SUM(ActiveSession) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
      {
        "type"   = "logQuery",
        "x"      = 0,
        "y"      = 12,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"    = "Distinct WorkSpaces Web usernames — last 5 minutes",
          "region"   = "eu-west-2",
          "view"     = "singleValue",
          "timezone" = "+0000",
          "logGroupNames" = [
            "/lambda/laa-workspacesweb-session-logs-20251125223414321800000003"
            # or better:
            # aws_cloudwatch_log_group.workspacesweb_session_logs[0].name
          ],
          # Multi-line Logs Insights query using a heredoc
          "query" = <<-QUERY
fields @timestamp, session_detail.username
| filter ispresent(session_detail.username)
| stats count_distinct(session_detail.username) as unique_usernames
QUERY
        }
      },

    ]
  })
}

resource "aws_cloudwatch_log_group" "workspacesweb_session_logs" {
  #checkov:skip=CKV_AWS_338:Long-term storage provided through S3 / XSIAM ingestion
  depends_on        = [aws_kms_key.workspacesweb_session_logs[0]]
  count             = local.create_resources ? 1 : 0
  kms_key_id        = aws_kms_key.workspacesweb_session_logs[0].arn
  name_prefix       = "/lambda/laa-workspacesweb-session-logs-"
  retention_in_days = 14
}