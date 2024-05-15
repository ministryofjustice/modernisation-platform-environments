locals {

  # baseline config
  preproduction_config = {
    
    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m6i.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 1 instance, reduced RAM as Azure usage doesn't warrant higher RAM
    # }
    baseline_route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
