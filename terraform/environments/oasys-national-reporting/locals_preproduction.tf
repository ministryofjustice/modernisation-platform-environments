locals {

  # baseline config
  preproduction_config = {
    
    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m4.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "r4.2xlarge" # 8 vCPUs, 61GB RAM x 1 instance
    # }
    baseline_route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
