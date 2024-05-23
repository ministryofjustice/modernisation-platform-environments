# environment specific settings
locals {

  # cloudwatch monitoring config
  development_cloudwatch_monitoring_options = {}

  development_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_nonprod_alarms"
        dba_pagerduty               = "hmpps_shef_dba_non_prod"
        dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      }
    }
  }

  development_config = {
    baseline_cloudwatch_log_groups = {	
      session-manager-logs = {	
        retention_in_days = 1	
      }	
      cwagent-var-log-messages = {	
        retention_in_days = 1	
      }	
      cwagent-var-log-secure = {	
        retention_in_days = 1	
      }	
      cwagent-windows-system = {	
        retention_in_days = 1	
      }	
      cwagent-oasys-autologoff = {	
        retention_in_days = 1	
      }	
      cwagent-web-logs = {	
        retention_in_days = 1	
      }	
    }
  }
}
