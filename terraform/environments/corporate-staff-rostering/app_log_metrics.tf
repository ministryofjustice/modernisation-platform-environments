# additional infra for these metrics can be found in the lambda sources
locals {
  application_log_metric_filters_meta = {
    log_group_name = local.lambda_cw_logs_xml_to_json.monitored_log_group
    namespace      = "ApplicationLogMetrics"
  }
  application_log_metric_filters_defaults = {
    log_group_name = local.application_log_metric_filters_meta.log_group_name

    metric_transformation = {
      namespace = local.application_log_metric_filters_meta.namespace
      value     = 1
      dimensions = {
        "InstanceId" = "$._.sourceLogStream"
      }
    }
  }
  application_log_metric_filters = {
    iwfm-enterprise-server-started = merge(local.application_log_metric_filters_defaults, {
      pattern = "{ $.Event.RenderingInfo.Message = %^iWFM Enterprise Server v.+ daemon started\\.% }"

      metric_transformation = merge(local.application_log_metric_filters_defaults.metric_transformation, {
        name = "iWFMEnterpriseServerStarted"
      })
    })
    iwfm-enterprise-server-terminated = merge(local.application_log_metric_filters_defaults, {
      # `\x28` and `\x29` denote `(` and `)` respectively.
      # this is because AWS do not allow parentheses in the filter pattern.
      pattern = "{ $.Event.RenderingInfo.Message = %^iWFM Enterprise Server \x28PID \\d+\x29 terminated\\.% }"

      metric_transformation = merge(local.application_log_metric_filters_defaults.metric_transformation, {
        name = "iWFMEnterpriseServerTerminated"
      })
    })
    invision-http-server-started = merge(local.application_log_metric_filters_defaults, {
      pattern = "{ $.Event.RenderingInfo.Message = %^InVision HTTP Server started\\.% }"

      metric_transformation = merge(local.application_log_metric_filters_defaults.metric_transformation, {
        name = "InVisionHTTPServerStarted"
      })
    })
    invision-http-server-terminated = merge(local.application_log_metric_filters_defaults, {
      # `\x28` and `\x29` denote `(` and `)` respectively.
      # this is because AWS do not allow parentheses in the filter pattern.
      pattern = "{ $.Event.RenderingInfo.Message = %^InVision HTTP Server \x28PID \\d+\x29 terminated\\.% }"

      metric_transformation = merge(local.application_log_metric_filters_defaults.metric_transformation, {
        name = "InVisionHTTPServerTerminated"
      })
    })
  }
}
