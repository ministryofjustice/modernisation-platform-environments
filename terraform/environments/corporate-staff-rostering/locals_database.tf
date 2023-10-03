locals {

  database_ssm_parameters = {
    parameters = {
      passwords = { description = "database passwords" }
    }
  }

}
