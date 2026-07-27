terraform{

    required_version = ">=1.5.0"
    
}


module "glue"{

    source="github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/data-factory-glue-database?ref=<git-sha>"

  database_name = "example"

  storage = {
    bucket_name = <bucket_name>
    prefix      = "example"
    kms_key_arn = "arn:aws:kms:eu-west-2:1234567890:key/example"
  }
  tags          = local.tags
}
