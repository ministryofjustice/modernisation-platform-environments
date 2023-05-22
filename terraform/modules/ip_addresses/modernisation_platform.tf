locals {

  mp_cidr = {
    development_test         = "10.26.0.0/16"
    preproduction_production = "10.27.0.0/16"

    hmpps-development   = "10.26.24.0/21"
    hmpps-test          = "10.26.8.0/21"
    hmpps-preproduction = "10.27.0.0/21"
    hmpps-production    = "10.27.8.0/21"
  }

}
