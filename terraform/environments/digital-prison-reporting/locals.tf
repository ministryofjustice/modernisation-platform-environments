#### This file can be used to store locals specific to the member account ####
#### DPR Specific ####
locals {
    project                    = local.application_data.accounts[local.environment].project_short_id
    # glue_db                    = local.application_data.accounts[local.environment].glue_db_name
    # glue_db_data_domain        = local.application_data.accounts[local.environment].glue_db_data_domain
    description                = local.application_data.accounts[local.environment].db_description
    create_db                  = local.application_data.accounts[local.environment].create_database
    glue_job                   = local.application_data.accounts[local.environment].glue_job_name
    create_job                 = local.application_data.accounts[local.environment].create_job
    create_sec_conf            = local.application_data.accounts[local.environment].create_security_conf
    env                        = local.environment
    s3_kms_arn                 = aws_kms_key.s3.arn
    kinesis_kms_arn            = aws_kms_key.kinesis-kms-key.arn
    kinesis_kms_id             = data.aws_kms_key.kinesis_kms_key.key_id
    create_bucket              = local.application_data.accounts[local.environment].setup_buckets
    account_id                 = data.aws_caller_identity.current.account_id
    account_region             = data.aws_region.current.name
    create_kinesis             = local.application_data.accounts[local.environment].create_kinesis_streams
    enable_glue_registry       = local.application_data.accounts[local.environment].create_glue_registries
    setup_buckets              = local.application_data.accounts[local.environment].setup_s3_buckets
    create_glue_connection     = local.application_data.accounts[local.environment].create_glue_connections
    image_id                   = local.application_data.accounts[local.environment].ami_image_id
    instance_type              = local.application_data.accounts[local.environment].ec2_instance_type
    create_datamart            = local.application_data.accounts[local.environment].setup_redshift
    redshift_cluster_name      = "${local.application_data.accounts[local.environment].project_short_id}-redshift-${local.environment}"
    kinesis_stream_ingestor    = "${local.application_data.accounts[local.environment].project_short_id}-kinesis-ingestor-${local.environment}"
    # DPR-378 #  kinesis_stream_data_domain = "${local.application_data.accounts[local.environment].project_short_id}-kinesis-data-domain-${local.environment}"
    kinesis_endpoint           = "https://kinesis.eu-west-2.amazonaws.com"

    all_tags = merge(
    local.tags,
        {
            Name = "${local.application_name}"
        }
    )
}