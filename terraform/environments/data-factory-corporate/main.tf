terraform{

    required_version = ">=1.7.0"
    
}


module "glue"{

    source= "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/data-factory-glue-database?ref=7cef415e42eb66482c2c1ea88de49ee44bd5481a"
    catalog_database_name = "example"

    storage = {
        bucket_name ="<bucket_name>"
        prefix      = "example"
        kms_key_arn = "arn:aws:kms:eu-west-2:1234567890:key/example"
            }
     tags          = local.tags
}
