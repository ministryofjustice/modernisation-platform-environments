terraform{

    required_version = ">=1.7.0"
    
}


module "glue"{

    source= "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/data-factory-glue-database?ref=7cef415e42eb66482c2c1ea88de49ee44bd5481a"
    catalog_database_name = "data_factory_corporate_glue_catalog"

    storage = {
        bucket_name ="place holder"
        prefix      = "place holder"
        kms_key_arn = "arn:aws:kms:eu-west-placeholder"
            }
     tags          = local.tags
}
