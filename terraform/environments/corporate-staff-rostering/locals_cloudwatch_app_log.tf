# additional infra for these metrics can be found in the lambda sources
locals {
  cloudwatch_app_log_metric_filters_meta = {
    log_group_name = "cwagent-windows-application-json"
    namespace      = "ApplicationLog"
  }
  cloudwatch_app_log_metric_filters_defaults = {
    log_group_name = local.cloudwatch_app_log_metric_filters_meta.log_group_name

    metric_transformation = {
      namespace = local.cloudwatch_app_log_metric_filters_meta.namespace
      value     = 1
      dimensions = {
        "InstanceId" = "$._.sourceLogStream"
      }
    }
  }
  cloudwatch_app_log_metric_filters = {
    iwfm-enterprise-server-started = merge(local.cloudwatch_app_log_metric_filters_defaults, {
      pattern = "{ $.Event.RenderingInfo.Message = %^iWFM Enterprise Server v.+ daemon started\\.% }"

      metric_transformation = merge(local.cloudwatch_app_log_metric_filters_defaults.metric_transformation, {
        name = "iWFMEnterpriseServerStarted"
      })
    })
    iwfm-enterprise-server-terminated = merge(local.cloudwatch_app_log_metric_filters_defaults, {
      # `\x28` and `\x29` denote `(` and `)` respectively.
      # this is because AWS do not allow parentheses in the filter pattern.
      pattern = "{ $.Event.RenderingInfo.Message = %^iWFM Enterprise Server \\x28PID \\d+\\x29 terminated\\.% }"

      metric_transformation = merge(local.cloudwatch_app_log_metric_filters_defaults.metric_transformation, {
        name = "iWFMEnterpriseServerTerminated"
      })
    })
    invision-http-server-started = merge(local.cloudwatch_app_log_metric_filters_defaults, {
      pattern = "{ $.Event.RenderingInfo.Message = %^InVision HTTP Server started\\.% }"

      metric_transformation = merge(local.cloudwatch_app_log_metric_filters_defaults.metric_transformation, {
        name = "InVisionHTTPServerStarted"
      })
    })
    invision-http-server-terminated = merge(local.cloudwatch_app_log_metric_filters_defaults, {
      # `\x28` and `\x29` denote `(` and `)` respectively.
      # this is because AWS do not allow parentheses in the filter pattern.
      pattern = "{ $.Event.RenderingInfo.Message = %^InVision HTTP Server \\x28PID \\d+\\x29 terminated\\.% }"

      metric_transformation = merge(local.cloudwatch_app_log_metric_filters_defaults.metric_transformation, {
        name = "InVisionHTTPServerTerminated"
      })
    })
  }
  cloudwatch_app_log_metric_alarms_defaults = {
    namespace           = local.cloudwatch_app_log_metric_filters_meta.namespace
    period              = 60
    evaluation_periods  = 1
    statistic           = "Sum"
    comparison_operator = "GreaterThanThreshold"
    threshold           = 2
    treat_missing_data  = "notBreaching"
  }
  # these alarms are applied directly to ec2 instances.
  # see the configs for individual instances.
  cloudwatch_app_log_metric_alarms = {
    app = {
      iwfm-enterprise-server-started = merge(local.cloudwatch_app_log_metric_alarms_defaults, {
        metric_name = local.cloudwatch_app_log_metric_filters.iwfm-enterprise-server-started.metric_transformation.name
      })
      iwfm-enterprise-server-terminated = merge(local.cloudwatch_app_log_metric_alarms_defaults, {
        metric_name = local.cloudwatch_app_log_metric_filters.iwfm-enterprise-server-terminated.metric_transformation.name
      })
    }
    web = {
      invision-http-server-started = merge(local.cloudwatch_app_log_metric_alarms_defaults, {
        metric_name = local.cloudwatch_app_log_metric_filters.invision-http-server-started.metric_transformation.name
      })
      invision-http-server-terminated = merge(local.cloudwatch_app_log_metric_alarms_defaults, {
        metric_name = local.cloudwatch_app_log_metric_filters.invision-http-server-terminated.metric_transformation.name
      })
    }
  }
}
