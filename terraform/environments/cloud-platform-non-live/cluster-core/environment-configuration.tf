locals {
  environment_configurations = {
    development_cluster = {
      enable_culium = true
    }
    development = {
      enable_culium = false
    }
    test = {
      enable_culium = false 
    }
    preproduction = {
      enable_culium = false
    }
    production = {
      enable_culium = false
    }
  }
}
