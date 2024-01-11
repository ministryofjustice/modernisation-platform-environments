resource "aws_cur_report_definition" "cur_planetfm" {
  provider                   = aws.us-east-1
  report_name                = "planetfm-cur-report-definition"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  s3_bucket                  = module.csr-report-bucket.bucket.id
  s3_region                  = "eu-west-2"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
  s3_prefix                  = "cur" 
}

module "csr-report-bucket" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

    bucket_prefix = "planetfm"
    versioning_enabled = false
    bucket_policy = [data.aws_iam_policy_document.cur_bucket_policy.json]
    force_destroy  = true
    replication_enabled = false
    sse_algorithm = "AES256"
    providers = {
        aws.bucket-replication = aws
    }

    tags = merge(local.tags, {
        Name = lower(format("cur-report-bucket-%s-%s", local.application_name, local.environment))
    })
}

data "aws_iam_policy_document" "cur_bucket_policy" {
    statement {
        sid       = "EnsureBucketOwnedByAccountForCURDelivery"
        effect    = "Allow"
        resources = [module.csr-report-bucket.bucket.arn]

        actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        ]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }

    statement {
        sid       = "GrantAccessToDeliverCURFiles"
        effect    = "Allow"
        resources = ["${module.csr-report-bucket.bucket.arn}/*"]
        actions   = ["s3:PutObject"]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }
}

resource "aws_athena_database" "cur" {
    name = "cur"
    bucket = module.csr-report-bucket.bucket.id
    encryption_configuration {
        encryption_option = "SSE_S3"
    }
}

resource "aws_athena_workgroup" "cur" {
    name = "cur"
    configuration {
        enforce_workgroup_configuration = true
        publish_cloudwatch_metrics_enabled = true

        engine_version {
            selected_engine_version = "Athena engine version 3"    
        }
        result_configuration {
            output_location = "s3://${module.csr-report-bucket.bucket.id}/output/"
        }
    }
}

resource "aws_glue_catalog_table" "report_status" {
    name = "status-table"
    database_name = aws_athena_database.cur.name
    table_type = "EXTERNAL_TABLE"

    storage_descriptor {
        input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
        location = "s3://${module.csr-report-bucket.bucket.id}/${aws_cur_report_definition.cur_planetfm.s3_prefix}/${aws_cur_report_definition.cur_planetfm.report_name}/cost_and_usage_data_status/"
        ser_de_info {
            name = "status_table"
            serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
            parameters = {
            "serialization.format" = "1"
            }
        }
        columns {
            name = "status"
            type = "string"
        }
    }
}

resource "aws_glue_catalog_table" "report" {
    name = "report-table"
    database_name = aws_athena_database.cur.name
    table_type = "EXTERNAL_TABLE"

    partition_keys {
        name = "year"
        type = "string"
    }
    partition_keys {
        name = "month"
        type = "string"
    }

    storage_descriptor {
        input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
        location = "s3://${module.csr-report-bucket.bucket.id}/${aws_cur_report_definition.cur_planetfm.s3_prefix}/${aws_cur_report_definition.cur_planetfm.report_name}/planetfm-cur-report-definition/"
        ser_de_info {
            name = "report_table"
            serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
            parameters = {
            "serialization.format" = "1"
            }
        }
        columns {
            name = "identity_line_item_id"
            type = "string"
        }
        columns {
            name = "identity_time_interval"
            type = "string"
        }
        columns {
            name = "bill_invoice_id"
            type = "string"
        }
        columns {
            name = "bill_invoicing_entity"
            type = "string"
        }
        columns {
            name = "bill_billing_entity"
            type = "string"
        }
        columns {
            name = "bill_bill_type"
            type = "string"
        }
        columns {
            name = "bill_payer_account_id"
            type = "string"
        }
        columns {
            name = "bill_billing_period_start_date"
            type = "timestamp"
        }
        columns {
            name = "bill_billing_period_end_date"
            type = "timestamp"
        }
        columns {
            name = "line_item_usage_account_id"
            type = "string"
        }
        columns {
            name = "line_item_line_item_type"
            type = "string"
        }
        columns {
            name = "line_item_usage_start_date"
            type = "timestamp"
        }
        columns {
            name = "line_item_usage_end_date"
            type = "timestamp"
        }
        columns {
            name = "line_item_product_code"
            type = "string"
        }
        columns {
            name = "line_item_usage_type"
            type = "string"
        }
        columns {
            name = "line_item_operation"
            type = "string"
        }
        columns {
            name = "line_item_availability_zone"
            type = "string"
        }
        columns {
            name = "line_item_resource_id"
            type = "string"
        }
        columns {
            name = "line_item_usage_amount"
            type = "double"
        }
        columns {
            name = "line_item_normalization_factor"
            type = "double"
        }
        columns {
            name = "line_item_normalized_usage_amount"
            type = "double"
        }
        columns {
            name = "line_item_currency_code"
            type = "string"
        }
        columns {
            name = "line_item_unblended_rate"
            type = "string"
        }
        columns {
            name = "line_item_unblended_cost"
            type = "double"
        }
        columns {
            name = "line_item_blended_rate"
            type = "string"
        }
        columns {
            name = "line_item_blended_cost"
            type = "double"
        }
        columns {
            name = "line_item_line_item_description"
            type = "string"
        }
        columns {
            name = "line_item_tax_type"
            type = "string"
        }
        columns {
            name = "line_item_net_unblended_rate"
            type = "string"
        }
        columns {
            name = "line_item_net_unblended_cost"
            type = "double"
        }
        columns {
            name = "line_item_legal_entity"
            type = "string"
        }  	
        columns {
            name = "product_product_name"
            type = "string"
        }
        columns {
            name = "product_purchase_option"
            type = "string"
        }
        columns {
            name = "product_size_flex"
            type = "string"
        }
        columns {
            name = "product_access_type"
            type = "string"
        }
        columns {
            name = "product_account_assistance"
            type = "string"
        }
        columns {
            name = "product_alarm_type"
            type = "string"
        }
        columns {
            name = "product_api_type"
            type = "string"
        }
        columns {
            name = "product_architectural_review"
            type = "string"
        }
        columns {
            name = "product_architecture"
            type = "string"
        }
        columns {
            name = "product_architecture_support"
            type = "string"
        }
        columns {
            name = "product_attachment_type"
            type = "string"
        }
        columns {
            name = "product_availability"
            type = "string"
        }
        columns {
            name = "product_availability_zone"
            type = "string"
        }
        columns {
            name = "product_awsresource"
            type = "string"
        }
	product_backupservice STRING,
	product_best_practices STRING,
	product_brioproductid STRING,
	product_broker_engine STRING,
	product_bundle STRING,
	product_bundle_description STRING,
	product_bundle_group STRING,
	product_cache_engine STRING,
	product_cache_type STRING,
	product_calling_type STRING,
	product_capacity STRING,
	product_capacitystatus STRING,
	product_case_severityresponse_times STRING,
	product_category STRING,
	product_chargeid STRING,
	product_ci_type STRING,
	product_classicnetworkingsupport STRING,
	product_clock_speed STRING,
	product_component STRING,
	product_compute_family STRING,
	product_compute_type STRING,
	product_connection_type STRING,
	product_content_type STRING,
	product_country STRING,
	product_counts_against_quota STRING,
	product_cputype STRING,
	product_current_generation STRING,
	product_customer_service_and_communities STRING,
	product_data STRING,
	product_data_transfer_quota STRING,
	product_data_type STRING,
	product_database_edition STRING,
	product_database_engine STRING,
	product_datatransferout STRING,
	product_dedicated_ebs_throughput STRING,
	product_deployment_option STRING,
	product_describes STRING,
	product_description STRING,
	product_direct_connect_location STRING,
	product_directory_size STRING,
	product_directory_type STRING,
	product_directory_type_description STRING,
	product_disableactivationconfirmationemail STRING,
	product_durability STRING,
	product_ecu STRING,
	product_edition STRING,
	product_endpoint STRING,
	product_endpoint_type STRING,
	product_engine_code STRING,
	product_enhanced_infrastructure_metrics STRING,
	product_enhanced_networking_support STRING,
	product_enhanced_networking_supported STRING,
	product_entity_type STRING,
	product_equivalentondemandsku STRING,
	product_event_type STRING,
	product_feature STRING,
	product_fee_code STRING,
	product_fee_description STRING,
	product_file_system_type STRING,
	product_finding_group STRING,
	product_finding_source STRING,
	product_finding_storage STRING,
	product_finding_type STRING,
	product_free_overage STRING,
	product_free_query_types STRING,
	product_free_tier STRING,
	product_free_trial STRING,
	product_free_usage_included STRING,
	product_from_location STRING,
	product_from_location_type STRING,
	product_from_region_code STRING,
	product_georegioncode STRING,
	product_gets STRING,
	product_gpu STRING,
	product_gpu_memory STRING,
	product_granularity STRING,
	product_group STRING,
	product_group_description STRING,
	product_included_services STRING,
	product_inference_type STRING,
	product_input_mode STRING,
	product_insightstype STRING,
	product_instance STRING,
	product_instance_family STRING,
	product_instance_function STRING,
	product_instance_name STRING,
	product_instance_type STRING,
	product_instance_type_family STRING,
	product_instances STRING,
	product_intel_avx2_available STRING,
	product_intel_avx_available STRING,
	product_intel_turbo_available STRING,
	product_invocation STRING,
	product_io STRING,
	product_iscommitcpsku STRING,
	product_job_type STRING,
	product_launch_support STRING,
	product_license STRING,
	product_license_model STRING,
	product_line_type STRING,
	product_location STRING,
	product_location_type STRING,
	product_logs_destination STRING,
	product_mailbox_storage STRING,
	product_marketoption STRING,
	product_max_iops_burst_performance STRING,
	product_max_iopsvolume STRING,
	product_max_throughputvolume STRING,
	product_max_volume_size STRING,
	product_maximum_extended_storage STRING,
	product_maximum_storage_volume STRING,
	product_memory STRING,
	product_memory_gib STRING,
	product_memorytype STRING,
	product_message_delivery_frequency STRING,
	product_message_delivery_order STRING,
	product_min_volume_size STRING,
	product_minimum_storage_volume STRING,
	product_multi_session STRING,
	product_network_performance STRING,
	product_normalization_size_factor STRING,
	product_operating_system STRING,
	product_operation STRING,
	product_operations_support STRING,
	product_ops_items STRING,
	product_origin STRING,
	product_os_license_model STRING,
	product_output_mode STRING,
	product_overage_type STRING,
	product_overhead STRING,
	product_pack_size STRING,
	product_parameter_type STRING,
	product_physical_cpu STRING,
	product_physical_gpu STRING,
	product_physical_processor STRING,
	product_platoclassificationtype STRING,
	product_platodataanalyzedtype STRING,
	product_platofeaturetype STRING,
	product_platoinstancename STRING,
	product_platoinstancetype STRING,
	product_platopagedatatype STRING,
	product_platopricingtype STRING,
	product_platoprotectionpolicytype STRING,
	product_platoprotocoltype STRING,
	product_platostoragename STRING,
	product_platostoragetype STRING,
	product_platotrafficdirection STRING,
	product_platotransfertype STRING,
	product_platousagetype STRING,
	product_platovolumetype STRING,
	product_port_speed STRING,
	product_pre_installed_sw STRING,
	product_pricing_unit STRING,
	product_primaryplaceofuse STRING,
	product_proactive_guidance STRING,
	product_processor_architecture STRING,
	product_processor_features STRING,
	product_product_family STRING,
	product_product_schema_description STRING,
	product_product_type STRING,
	product_productgroupid STRING,
	product_productsubgroup STRING,
	product_programmatic_case_management STRING,
	product_provisioned STRING,
	product_purchaseterm STRING,
	product_q_present STRING,
	product_queue_type STRING,
	product_ratetype STRING,
	product_recipient STRING,
	product_region STRING,
	product_region_code STRING,
	product_replication_type STRING,
	product_request_description STRING,
	product_request_type STRING,
	product_resource STRING,
	product_resource_assessment STRING,
	product_resource_endpoint STRING,
	product_resource_price_group STRING,
	product_resource_type STRING,
	product_response STRING,
	product_rootvolume STRING,
	product_routing_target STRING,
	product_routing_type STRING,
	product_running_mode STRING,
	product_scan_type STRING,
	product_servicecode STRING,
	product_servicename STRING,
	product_size STRING,
	product_sku STRING,
	product_snapshotarchivefeetype STRING,
	product_software_included STRING,
	product_standard_group STRING,
	product_standard_storage STRING,
	product_standard_storage_retention_included STRING,
	product_steps STRING,
	product_storage STRING,
	product_storage_class STRING,
	product_storage_media STRING,
	product_storage_type STRING,
	product_subcategory STRING,
	product_subscription_type STRING,
	product_supported_modes STRING,
	product_technical_support STRING,
	product_tenancy STRING,
	product_thirdparty_software_support STRING,
	product_throughput STRING,
	product_throughput_capacity STRING,
	product_throughput_class STRING,
	product_tickettype STRING,
	product_tiertype STRING,
	product_time_window STRING,
	product_titan_model STRING,
	product_to_location STRING,
	product_to_location_type STRING,
	product_to_region_code STRING,
	product_training STRING,
	product_transaction_type STRING,
	product_transfer_type STRING,
	product_type STRING,
	product_type_description STRING,
	product_updates STRING,
	product_usage_family STRING,
	product_usage_group STRING,
	product_usage_volume STRING,
	product_usagetype STRING,
	product_uservolume STRING,
	product_vcpu STRING,
	product_version STRING,
	product_video_memory_gib STRING,
	product_virtual_interface_type STRING,
	product_vmwareproductid STRING,
	product_vmwareregion STRING,
	product_volume_api_name STRING,
	product_volume_type STRING,
	product_vpcnetworkingsupport STRING,
	product_who_can_open_cases STRING,
	product_with_active_users STRING,
	pricing_lease_contract_length STRING,
	pricing_offering_class STRING,
	pricing_purchase_option STRING,
	pricing_rate_code STRING,
	pricing_rate_id STRING,
	pricing_currency STRING,
	pricing_public_on_demand_cost DOUBLE,
	pricing_public_on_demand_rate STRING,
	pricing_term STRING,
	pricing_unit STRING,
	reservation_amortized_upfront_cost_for_usage DOUBLE,
	reservation_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_effective_cost DOUBLE,
	reservation_end_time STRING,
	reservation_modification_status STRING,
	reservation_net_amortized_upfront_cost_for_usage DOUBLE,
	reservation_net_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_net_effective_cost DOUBLE,
	reservation_net_recurring_fee_for_usage DOUBLE,
	reservation_net_unused_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_net_unused_recurring_fee DOUBLE,
	reservation_net_upfront_value DOUBLE,
	reservation_normalized_units_per_reservation STRING,
	reservation_number_of_reservations STRING,
	reservation_recurring_fee_for_usage DOUBLE,
	reservation_start_time STRING,
	reservation_subscription_id STRING,
	reservation_total_reserved_normalized_units STRING,
	reservation_total_reserved_units STRING,
	reservation_units_per_reservation STRING,
	reservation_unused_amortized_upfront_fee_for_billing_period DOUBLE,
	reservation_unused_normalized_unit_quantity DOUBLE,
	reservation_unused_quantity DOUBLE,
	reservation_unused_recurring_fee DOUBLE,
	reservation_upfront_value DOUBLE,
	discount_edp_discount DOUBLE,
	discount_total_discount DOUBLE,
	savings_plan_total_commitment_to_date DOUBLE,
	savings_plan_savings_plan_a_r_n STRING,
	savings_plan_savings_plan_rate DOUBLE,
	savings_plan_used_commitment DOUBLE,
	savings_plan_savings_plan_effective_cost DOUBLE,
	savings_plan_amortized_upfront_commitment_for_billing_period DOUBLE,
	savings_plan_recurring_commitment_for_billing_period DOUBLE,
	savings_plan_start_time STRING,
	savings_plan_end_time STRING,
	savings_plan_offering_type STRING,
	savings_plan_payment_option STRING,
	savings_plan_purchase_term STRING,
	savings_plan_region STRING,
	savings_plan_net_savings_plan_effective_cost DOUBLE,
	savings_plan_net_amortized_upfront_commitment_for_billing_period DOUBLE,
	savings_plan_net_recurring_commitment_for_billing_period DOUBLE,
	resource_tags_aws_created_by STRING,
	resource_tags_user_stack STRING,
	resource_tags_user_app_kubernetes_io_name STRING,
	resource_tags_user_application STRING,
	resource_tags_user_business_unit STRING,
	resource_tags_user_component STRING,
	resource_tags_user_eks_cluster_name STRING,
	resource_tags_user_environment_name STRING,
	resource_tags_user_infrastructure_support STRING,
	resource_tags_user_is_production STRING,
	resource_tags_user_namespace STRING,
	resource_tags_user_owner STRING,
	resource_tags_user_runbook STRING,
	resource_tags_user_source_code STRING
    }
}
