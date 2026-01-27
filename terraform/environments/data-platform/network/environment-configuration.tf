locals {
  environment_configurations = {
    development = {
      /* Transit Gateway Routes
         TODO: Move these to configuration/network.yml
      */
      transit_gateway_routes = {
        internal       = "10.0.0.0/8"
        cloud_platform = "172.20.0.0/16"
      }
    }
    test          = {}
    preproduction = {}
    production    = {}
  }
}
