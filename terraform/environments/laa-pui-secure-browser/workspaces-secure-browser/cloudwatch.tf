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
        "type" = "metric",
        "x"    = 0, "y" = 12, "width" = 18, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Unique Users — per hour",
          "view"     = "timeSeries",
          "stacked"  = false,
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 3600,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "Unique users (COUNT DisplayLatency)",
                "expression" = "SELECT COUNT(DisplayLatency) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId, UserName) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
      {
        "type" = "metric",
        "x"    = 18, "y" = 12, "width" = 6, "height" = 6,
        "properties" = {
          "title"    = "WorkSpaces Web Unique Users — last 24 hours",
          "view"     = "singleValue",
          "stacked"  = false,
          "start"    = "-PT24H",
          "region"   = "eu-west-2",
          "timezone" = "+0000",
          "period"   = 86400,
          "metrics" = [
            [
              {
                "id"         = "q1",
                "label"      = "Unique users (COUNT DisplayLatency)",
                "expression" = "SELECT COUNT(DisplayLatency) FROM SCHEMA(\"AWS/WorkSpacesWeb\", PortalId, UserName) WHERE PortalId = '${local.portal_ids.external_1}'"
              }
            ]
          ]
        }
      },
    ]
  })
}
