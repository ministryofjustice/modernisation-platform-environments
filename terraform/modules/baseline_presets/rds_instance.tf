locals {

  rds_instance = {

    config = {

      # example configuration
      default = {
        ssm_parameters_prefix     = "rds_instance/"
        iam_resource_names_prefix = "rds-instance"
      }
    }

    instance = {

      default = {
        identifier        = "rds-instance"
        allocated_storage = 10
        db_name           = "rds-instance"
        engine            = "mysql"
        instance_class    = "db.t3.micro"
        username          = "example"
      }
    }
  }
}