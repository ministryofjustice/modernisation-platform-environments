terraform{

    required_version = ">=1.7.0"
}


module "glue "{

    source="./corporate_data/modules/glue_catalog"
    description ="glue_table"

    database_name = "corporate_database"
    database_description = "Corporate Glue database for S3 datasets"

    location_uri=

}