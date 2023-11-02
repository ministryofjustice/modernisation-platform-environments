locals {

  join_domain_ssm_parameters_dev_test = {
    prefix = "/"
    postfix = "_dev/"
    parameters = {
        credentials = {}
    }
  }
  

  join_domain_ssm_parameters_prod_preprod = {
    prefix = "/"
    postfix = "_prod/"
    parameters = {
        credentials = {}
    }
  }


  join_domain_ssm_parameters_by_environment = {
    development   = local.join_domain_ssm_parameters_dev_test
    test          = local.join_domain_ssm_parameters_dev_test
    production    = local.join_domain_ssm_parameters_prod_preprod
    preproduction = local.join_domain_ssm_parameters_prod_preprod
  }

  join_domain_ssm_parameters = local.join_domain_ssm_parameters_by_environment[local.environment]

}
