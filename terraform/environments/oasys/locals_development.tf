locals {

  baseline_presets_development = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "oasys_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    cloudwatch_log_groups = {
      session-manager-logs     = { retention_in_days = 1 }
      cwagent-var-log-messages = { retention_in_days = 1 }
      cwagent-var-log-secure   = { retention_in_days = 1 }
      cwagent-windows-system   = { retention_in_days = 1 }
      cwagent-oasys-autologoff = { retention_in_days = 1 }
      cwagent-web-logs         = { retention_in_days = 1 }
    }

    ec2_instances = {
      audit-vault = merge(local.audit_vault, {
        ebs_volumes = {
          # "/dev/sdb" = { label = "app", snapshot_id = "snap-072a42704cb38f785", size = 300 }
          "/dev/sdb" = { label = "app", size = 300 }
        }
        instance = merge(local.audit_vault.instance, {
          instance_type = "r7i.xlarge"
        })
        tags = merge(local.audit_vault.tags, {
          instance-scheduling = "skip-scheduling"
        })
      })

    }
  }
}
