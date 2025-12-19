locals {
  environment_configurations = {
    development = {
      /* AUTOSCALER */
      autoscaler = {
        enable_overprovision   = true
        enable_vpa_recommender = false
      }
    }
  }
}