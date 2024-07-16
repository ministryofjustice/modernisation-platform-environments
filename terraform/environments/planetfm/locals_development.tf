locals {

  baseline_presets_development = {
    options = {
      # disable some features as environments gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {
  }
}
