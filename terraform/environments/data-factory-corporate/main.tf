terraform{

    required_version = ">=1.7.0"
}


module "glue"{

    source="git::https://github.com/ministryofjustice/modernisation-platform-environments.git//terraform/environments/data-factory-corporate/corporate_data/modules/glue_catalog?ref=abc1234567890abc1234567890abc1234567890a"
    description ="glue_table"

    database_name = "corporate_database"
    database_description = "Corporate Glue database for S3 datasets"
    location_uri=""

}