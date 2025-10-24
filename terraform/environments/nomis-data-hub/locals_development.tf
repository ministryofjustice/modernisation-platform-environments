locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {
    patch_manager = {
      patch_schedules = {
        group1 = "cron(10 06 ? * TUE *)" # 06:10 for non-prod env's as we have to work around the overnight shutdown  
      }
      maintenance_window_duration = 2
      maintenance_window_cutoff   = 1
      patch_classifications = {
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
      }
    }
  }
}
