resource "aws_cur_report_definition" "cost_usage_report" {

  provider                   = aws.us-east-1
  report_name                = lower(format("%s-cost-usage-report", var.application_name))
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  s3_bucket                  = module.s3_bucket.bucket.id
  s3_region                  = "eu-west-2"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
  s3_prefix                  = "cur"
  depends_on                 = [module.s3_bucket] #ensures bucket permissions are applied before athena bucket access validation checks run
}

#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "s3_bucket" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash; skip as this is MoJ Repo

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_prefix      = "cost-usage-report-"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.cur_bucket_policy.json]

  force_destroy       = true
  replication_enabled = false
  sse_algorithm       = "AES256"
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  tags = merge(var.tags, {
    Name = lower(format("cost-usage-report-bucket-%s", var.application_name))
  })
}

data "aws_iam_policy_document" "cur_bucket_policy" {

  statement {
    sid       = "EnsureBucketOwnedByAccountForCURDelivery"
    effect    = "Allow"
    resources = [module.s3_bucket.bucket.arn]

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cur:us-east-1:${var.account_number}:definition/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
  }

  statement {
    sid       = "GrantAccessToDeliverCURFiles"
    effect    = "Allow"
    resources = ["${module.s3_bucket.bucket.arn}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cur:us-east-1:${var.account_number}:definition/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }

    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
  }
}

resource "aws_athena_database" "cur" {

  name   = "cost_usage_report"
  bucket = module.s3_bucket.bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
  force_destroy = true
}

resource "aws_athena_workgroup" "cur" {

  name = "cost_usage_report"
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://${module.s3_bucket.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  force_destroy = true
}

resource "aws_glue_catalog_table" "report_status" {

  name          = "status-table"
  database_name = aws_athena_database.cur.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    location      = "s3://${module.s3_bucket.bucket.id}/${aws_cur_report_definition.cost_usage_report.s3_prefix}/${aws_cur_report_definition.cost_usage_report.report_name}/cost_and_usage_data_status/"
    ser_de_info {
      name                  = "status_table"
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

  name          = "report-table"
  database_name = aws_athena_database.cur.name
  table_type    = "EXTERNAL_TABLE"

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }

  parameters = {
    EXTERNAL                    = "TRUE"
    "parquet.compression"       = "SNAPPY"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2024,2030"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "storage.location.template" = "s3://${module.s3_bucket.bucket.id}/${aws_cur_report_definition.cost_usage_report.s3_prefix}/${aws_cur_report_definition.cost_usage_report.report_name}/${aws_cur_report_definition.cost_usage_report.report_name}/year=$${year}/month=$${month}"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    location      = "s3://${module.s3_bucket.bucket.id}/${aws_cur_report_definition.cost_usage_report.s3_prefix}/${aws_cur_report_definition.cost_usage_report.report_name}/${aws_cur_report_definition.cost_usage_report.report_name}/"
    ser_de_info {
      name                  = "report_table"
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
    columns {
      name = "product_backupservice"
      type = "string"
    }
    columns {
      name = "product_best_practices"
      type = "string"
    }
    columns {
      name = "product_brioproductid"
      type = "string"
    }
    columns {
      name = "product_broker_engine"
      type = "string"
    }
    columns {
      name = "product_bundle"
      type = "string"
    }
    columns {
      name = "product_bundle_description"
      type = "string"
    }
    columns {
      name = "product_bundle_group"
      type = "string"
    }
    columns {
      name = "product_cache_engine"
      type = "string"
    }
    columns {
      name = "product_cache_type"
      type = "string"
    }
    columns {
      name = "product_calling_type"
      type = "string"
    }
    columns {
      name = "product_capacity"
      type = "string"
    }
    columns {
      name = "product_capacitystatus"
      type = "string"
    }
    columns {
      name = "product_case_severityresponse_times"
      type = "string"
    }
    columns {
      name = "product_category"
      type = "string"
    }
    columns {
      name = "product_chargeid"
      type = "string"
    }
    columns {
      name = "product_ci_type"
      type = "string"
    }
    columns {
      name = "product_classicnetworkingsupport"
      type = "string"
    }
    columns {
      name = "product_clock_speed"
      type = "string"
    }
    columns {
      name = "product_component"
      type = "string"
    }
    columns {
      name = "product_compute_family"
      type = "string"
    }
    columns {
      name = "product_compute_type"
      type = "string"
    }
    columns {
      name = "product_connection_type"
      type = "string"
    }
    columns {
      name = "product_content_type"
      type = "string"
    }
    columns {
      name = "product_country"
      type = "string"
    }
    columns {
      name = "product_counts_against_quota"
      type = "string"
    }
    columns {
      name = "product_cputype"
      type = "string"
    }
    columns {
      name = "product_current_generation"
      type = "string"
    }
    columns {
      name = "product_customer_service_and_communities"
      type = "string"
    }
    columns {
      name = "product_data"
      type = "string"
    }
    columns {
      name = "product_data_transfer_quota"
      type = "string"
    }
    columns {
      name = "product_data_type"
      type = "string"
    }
    columns {
      name = "product_database_edition"
      type = "string"
    }
    columns {
      name = "product_database_engine"
      type = "string"
    }
    columns {
      name = "product_datatransferout"
      type = "string"
    }
    columns {
      name = "product_dedicated_ebs_throughput"
      type = "string"
    }
    columns {
      name = "product_deployment_option"
      type = "string"
    }
    columns {
      name = "product_describes"
      type = "string"
    }
    columns {
      name = "product_description"
      type = "string"
    }
    columns {
      name = "product_direct_connect_location"
      type = "string"
    }
    columns {
      name = "product_directory_size"
      type = "string"
    }
    columns {
      name = "product_directory_type"
      type = "string"
    }
    columns {
      name = "product_directory_type_description"
      type = "string"
    }
    columns {
      name = "product_disableactivationconfirmationemail"
      type = "string"
    }
    columns {
      name = "product_durability"
      type = "string"
    }
    columns {
      name = "product_ecu"
      type = "string"
    }
    columns {
      name = "product_edition"
      type = "string"
    }
    columns {
      name = "product_endpoint"
      type = "string"
    }
    columns {
      name = "product_endpoint_type"
      type = "string"
    }
    columns {
      name = "product_engine_code"
      type = "string"
    }
    columns {
      name = "product_enhanced_infrastructure_metrics"
      type = "string"
    }
    columns {
      name = "product_enhanced_networking_support"
      type = "string"
    }
    columns {
      name = "product_enhanced_networking_supported"
      type = "string"
    }
    columns {
      name = "product_entity_type"
      type = "string"
    }
    columns {
      name = "product_equivalentondemandsku"
      type = "string"
    }
    columns {
      name = "product_event_type"
      type = "string"
    }
    columns {
      name = "product_feature"
      type = "string"
    }
    columns {
      name = "product_fee_code"
      type = "string"
    }
    columns {
      name = "product_fee_description"
      type = "string"
    }
    columns {
      name = "product_file_system_type"
      type = "string"
    }
    columns {
      name = "product_finding_group"
      type = "string"
    }
    columns {
      name = "product_finding_source"
      type = "string"
    }
    columns {
      name = "product_finding_storage"
      type = "string"
    }
    columns {
      name = "product_finding_type"
      type = "string"
    }
    columns {
      name = "product_free_overage"
      type = "string"
    }
    columns {
      name = "product_free_query_types"
      type = "string"
    }
    columns {
      name = "product_free_tier"
      type = "string"
    }
    columns {
      name = "product_free_trial"
      type = "string"
    }
    columns {
      name = "product_free_usage_included"
      type = "string"
    }
    columns {
      name = "product_from_location"
      type = "string"
    }
    columns {
      name = "product_from_location_type"
      type = "string"
    }
    columns {
      name = "product_from_region_code"
      type = "string"
    }
    columns {
      name = "product_georegioncode"
      type = "string"
    }
    columns {
      name = "product_gets"
      type = "string"
    }
    columns {
      name = "product_gpu"
      type = "string"
    }
    columns {
      name = "product_gpu_memory"
      type = "string"
    }
    columns {
      name = "product_granularity"
      type = "string"
    }
    columns {
      name = "product_group"
      type = "string"
    }
    columns {
      name = "product_group_description"
      type = "string"
    }
    columns {
      name = "product_included_services"
      type = "string"
    }
    columns {
      name = "product_inference_type"
      type = "string"
    }
    columns {
      name = "product_input_mode"
      type = "string"
    }
    columns {
      name = "product_insightstype"
      type = "string"
    }
    columns {
      name = "product_instance"
      type = "string"
    }
    columns {
      name = "product_instance_family"
      type = "string"
    }
    columns {
      name = "product_instance_function"
      type = "string"
    }
    columns {
      name = "product_instance_name"
      type = "string"
    }
    columns {
      name = "product_instance_type"
      type = "string"
    }
    columns {
      name = "product_instance_type_family"
      type = "string"
    }
    columns {
      name = "product_instances"
      type = "string"
    }
    columns {
      name = "product_intel_avx2_available"
      type = "string"
    }
    columns {
      name = "product_intel_avx_available"
      type = "string"
    }
    columns {
      name = "product_intel_turbo_available"
      type = "string"
    }
    columns {
      name = "product_invocation"
      type = "string"
    }
    columns {
      name = "product_io"
      type = "string"
    }
    columns {
      name = "product_iscommitcpsku"
      type = "string"
    }
    columns {
      name = "product_job_type"
      type = "string"
    }
    columns {
      name = "product_launch_support"
      type = "string"
    }
    columns {
      name = "product_license"
      type = "string"
    }
    columns {
      name = "product_license_model"
      type = "string"
    }
    columns {
      name = "product_line_type"
      type = "string"
    }
    columns {
      name = "product_location"
      type = "string"
    }
    columns {
      name = "product_location_type"
      type = "string"
    }
    columns {
      name = "product_logs_destination"
      type = "string"
    }
    columns {
      name = "product_mailbox_storage"
      type = "string"
    }
    columns {
      name = "product_marketoption"
      type = "string"
    }
    columns {
      name = "product_max_iops_burst_performance"
      type = "string"
    }
    columns {
      name = "product_max_iopsvolume"
      type = "string"
    }
    columns {
      name = "product_max_throughputvolume"
      type = "string"
    }
    columns {
      name = "product_max_volume_size"
      type = "string"
    }
    columns {
      name = "product_maximum_extended_storage"
      type = "string"
    }
    columns {
      name = "product_maximum_storage_volume"
      type = "string"
    }
    columns {
      name = "product_memory"
      type = "string"
    }
    columns {
      name = "product_memory_gib"
      type = "string"
    }
    columns {
      name = "product_memorytype"
      type = "string"
    }
    columns {
      name = "product_message_delivery_frequency"
      type = "string"
    }
    columns {
      name = "product_message_delivery_order"
      type = "string"
    }
    columns {
      name = "product_min_volume_size"
      type = "string"
    }
    columns {
      name = "product_minimum_storage_volume"
      type = "string"
    }
    columns {
      name = "product_multi_session"
      type = "string"
    }
    columns {
      name = "product_network_performance"
      type = "string"
    }
    columns {
      name = "product_normalization_size_factor"
      type = "string"
    }
    columns {
      name = "product_operating_system"
      type = "string"
    }
    columns {
      name = "product_operation"
      type = "string"
    }
    columns {
      name = "product_operations_support"
      type = "string"
    }
    columns {
      name = "product_ops_items"
      type = "string"
    }
    columns {
      name = "product_origin"
      type = "string"
    }
    columns {
      name = "product_os_license_model"
      type = "string"
    }
    columns {
      name = "product_output_mode"
      type = "string"
    }
    columns {
      name = "product_overage_type"
      type = "string"
    }
    columns {
      name = "product_overhead"
      type = "string"
    }
    columns {
      name = "product_pack_size"
      type = "string"
    }
    columns {
      name = "product_parameter_type"
      type = "string"
    }
    columns {
      name = "product_physical_cpu"
      type = "string"
    }
    columns {
      name = "product_physical_gpu"
      type = "string"
    }
    columns {
      name = "product_physical_processor"
      type = "string"
    }
    columns {
      name = "product_platoclassificationtype"
      type = "string"
    }
    columns {
      name = "product_platodataanalyzedtype"
      type = "string"
    }
    columns {
      name = "product_platofeaturetype"
      type = "string"
    }
    columns {
      name = "product_platoinstancename"
      type = "string"
    }
    columns {
      name = "product_platoinstancetype"
      type = "string"
    }
    columns {
      name = "product_platopagedatatype"
      type = "string"
    }
    columns {
      name = "product_platopricingtype"
      type = "string"
    }
    columns {
      name = "product_platoprotectionpolicytype"
      type = "string"
    }
    columns {
      name = "product_platoprotocoltype"
      type = "string"
    }
    columns {
      name = "product_platostoragename"
      type = "string"
    }
    columns {
      name = "product_platostoragetype"
      type = "string"
    }
    columns {
      name = "product_platotrafficdirection"
      type = "string"
    }
    columns {
      name = "product_platotransfertype"
      type = "string"
    }
    columns {
      name = "product_platousagetype"
      type = "string"
    }
    columns {
      name = "product_platovolumetype"
      type = "string"
    }
    columns {
      name = "product_port_speed"
      type = "string"
    }
    columns {
      name = "product_pre_installed_sw"
      type = "string"
    }
    columns {
      name = "product_pricing_unit"
      type = "string"
    }
    columns {
      name = "product_primaryplaceofuse"
      type = "string"
    }
    columns {
      name = "product_proactive_guidance"
      type = "string"
    }
    columns {
      name = "product_processor_architecture"
      type = "string"
    }
    columns {
      name = "product_processor_features"
      type = "string"
    }
    columns {
      name = "product_product_family"
      type = "string"
    }
    columns {
      name = "product_product_schema_description"
      type = "string"
    }
    columns {
      name = "product_product_type"
      type = "string"
    }
    columns {
      name = "product_productgroupid"
      type = "string"
    }
    columns {
      name = "product_productsubgroup"
      type = "string"
    }
    columns {
      name = "product_programmatic_case_management"
      type = "string"
    }
    columns {
      name = "product_provisioned"
      type = "string"
    }
    columns {
      name = "product_purchaseterm"
      type = "string"
    }
    columns {
      name = "product_q_present"
      type = "string"
    }
    columns {
      name = "product_queue_type"
      type = "string"
    }
    columns {
      name = "product_ratetype"
      type = "string"
    }
    columns {
      name = "product_recipient"
      type = "string"
    }
    columns {
      name = "product_region"
      type = "string"
    }
    columns {
      name = "product_region_code"
      type = "string"
    }
    columns {
      name = "product_replication_type"
      type = "string"
    }
    columns {
      name = "product_request_description"
      type = "string"
    }
    columns {
      name = "product_request_type"
      type = "string"
    }
    columns {
      name = "product_resource"
      type = "string"
    }
    columns {
      name = "product_resource_assessment"
      type = "string"
    }
    columns {
      name = "product_resource_endpoint"
      type = "string"
    }
    columns {
      name = "product_resource_price_group"
      type = "string"
    }
    columns {
      name = "product_resource_type"
      type = "string"
    }
    columns {
      name = "product_response"
      type = "string"
    }
    columns {
      name = "product_rootvolume"
      type = "string"
    }
    columns {
      name = "product_routing_target"
      type = "string"
    }
    columns {
      name = "product_routing_type"
      type = "string"
    }
    columns {
      name = "product_running_mode"
      type = "string"
    }
    columns {
      name = "product_scan_type"
      type = "string"
    }
    columns {
      name = "product_servicecode"
      type = "string"
    }
    columns {
      name = "product_servicename"
      type = "string"
    }
    columns {
      name = "product_size"
      type = "string"
    }
    columns {
      name = "product_sku"
      type = "string"
    }
    columns {
      name = "product_snapshotarchivefeetype"
      type = "string"
    }
    columns {
      name = "product_software_included"
      type = "string"
    }
    columns {
      name = "product_standard_group"
      type = "string"
    }
    columns {
      name = "product_standard_storage"
      type = "string"
    }
    columns {
      name = "product_standard_storage_retention_included"
      type = "string"
    }
    columns {
      name = "product_steps"
      type = "string"
    }
    columns {
      name = "product_storage"
      type = "string"
    }
    columns {
      name = "product_storage_class"
      type = "string"
    }
    columns {
      name = "product_storage_media"
      type = "string"
    }
    columns {
      name = "product_storage_type"
      type = "string"
    }
    columns {
      name = "product_subcategory"
      type = "string"
    }
    columns {
      name = "product_subscription_type"
      type = "string"
    }
    columns {
      name = "product_supported_modes"
      type = "string"
    }
    columns {
      name = "product_technical_support"
      type = "string"
    }
    columns {
      name = "product_tenancy"
      type = "string"
    }
    columns {
      name = "product_thirdparty_software_support"
      type = "string"
    }
    columns {
      name = "product_throughput"
      type = "string"
    }
    columns {
      name = "product_throughput_capacity"
      type = "string"
    }
    columns {
      name = "product_throughput_class"
      type = "string"
    }
    columns {
      name = "product_tickettype"
      type = "string"
    }
    columns {
      name = "product_tiertype"
      type = "string"
    }
    columns {
      name = "product_time_window"
      type = "string"
    }
    columns {
      name = "product_titan_model"
      type = "string"
    }
    columns {
      name = "product_to_location"
      type = "string"
    }
    columns {
      name = "product_to_location_type"
      type = "string"
    }
    columns {
      name = "product_to_region_code"
      type = "string"
    }
    columns {
      name = "product_training"
      type = "string"
    }
    columns {
      name = "product_transaction_type"
      type = "string"
    }
    columns {
      name = "product_transfer_type"
      type = "string"
    }
    columns {
      name = "product_type"
      type = "string"
    }
    columns {
      name = "product_type_description"
      type = "string"
    }
    columns {
      name = "product_updates"
      type = "string"
    }
    columns {
      name = "product_usage_family"
      type = "string"
    }
    columns {
      name = "product_usage_group"
      type = "string"
    }
    columns {
      name = "product_usage_volume"
      type = "string"
    }
    columns {
      name = "product_usagetype"
      type = "string"
    }
    columns {
      name = "product_uservolume"
      type = "string"
    }
    columns {
      name = "product_vcpu"
      type = "string"
    }
    columns {
      name = "product_version"
      type = "string"
    }
    columns {
      name = "product_video_memory_gib"
      type = "string"
    }
    columns {
      name = "product_virtual_interface_type"
      type = "string"
    }
    columns {
      name = "product_vmwareproductid"
      type = "string"
    }
    columns {
      name = "product_vmwareregion"
      type = "string"
    }
    columns {
      name = "product_volume_api_name"
      type = "string"
    }
    columns {
      name = "product_volume_type"
      type = "string"
    }
    columns {
      name = "product_vpcnetworkingsupport"
      type = "string"
    }
    columns {
      name = "product_who_can_open_cases"
      type = "string"
    }
    columns {
      name = "product_with_active_users"
      type = "string"
    }
    columns {
      name = "pricing_lease_contract_length"
      type = "string"
    }
    columns {
      name = "pricing_offering_class"
      type = "string"
    }
    columns {
      name = "pricing_purchase_option"
      type = "string"
    }
    columns {
      name = "pricing_rate_code"
      type = "string"
    }
    columns {
      name = "pricing_rate_id"
      type = "string"
    }
    columns {
      name = "pricing_currency"
      type = "string"
    }
    columns {
      name = "pricing_public_on_demand_cost"
      type = "double"
    }
    columns {
      name = "pricing_public_on_demand_rate"
      type = "string"
    }
    columns {
      name = "pricing_term"
      type = "string"
    }
    columns {
      name = "pricing_unit"
      type = "string"
    }
    columns {
      name = "reservation_amortized_upfront_cost_for_usage"
      type = "double"
    }
    columns {
      name = "reservation_amortized_upfront_fee_for_billing_period"
      type = "double"
    }
    columns {
      name = "reservation_effective_cost"
      type = "double"
    }
    columns {
      name = "reservation_end_time"
      type = "string"
    }
    columns {
      name = "reservation_modification_status"
      type = "string"
    }
    columns {
      name = "reservation_net_amortized_upfront_cost_for_usage"
      type = "double"
    }
    columns {
      name = "reservation_net_amortized_upfront_fee_for_billing_period"
      type = "double"
    }
    columns {
      name = "reservation_net_effective_cost"
      type = "double"
    }
    columns {
      name = "reservation_net_recurring_fee_for_usage"
      type = "double"
    }
    columns {
      name = "reservation_net_unused_amortized_upfront_fee_for_billing_period"
      type = "double"
    }
    columns {
      name = "reservation_net_unused_recurring_fee"
      type = "double"
    }
    columns {
      name = "reservation_net_upfront_value"
      type = "double"
    }
    columns {
      name = "reservation_normalized_units_per_reservation"
      type = "string"
    }
    columns {
      name = "reservation_number_of_reservations"
      type = "string"
    }
    columns {
      name = "reservation_recurring_fee_for_usage"
      type = "double"
    }
    columns {
      name = "reservation_start_time"
      type = "string"
    }
    columns {
      name = "reservation_subscription_id"
      type = "string"
    }
    columns {
      name = "reservation_total_reserved_normalized_units"
      type = "string"
    }
    columns {
      name = "reservation_total_reserved_units"
      type = "string"
    }
    columns {
      name = "reservation_units_per_reservation"
      type = "string"
    }
    columns {
      name = "reservation_unused_amortized_upfront_fee_for_billing_period"
      type = "double"
    }
    columns {
      name = "reservation_unused_normalized_unit_quantity"
      type = "double"
    }
    columns {
      name = "reservation_unused_quantity"
      type = "double"
    }
    columns {
      name = "reservation_unused_recurring_fee"
      type = "double"
    }
    columns {
      name = "reservation_upfront_value"
      type = "double"
    }
    columns {
      name = "discount_edp_discount"
      type = "double"
    }
    columns {
      name = "discount_total_discount"
      type = "double"
    }
    columns {
      name = "savings_plan_total_commitment_to_date"
      type = "double"
    }
    columns {
      name = "savings_plan_savings_plan_a_r_n"
      type = "string"
    }
    columns {
      name = "savings_plan_savings_plan_rate"
      type = "double"
    }
    columns {
      name = "savings_plan_used_commitment"
      type = "double"
    }
    columns {
      name = "savings_plan_savings_plan_effective_cost"
      type = "double"
    }
    columns {
      name = "savings_plan_amortized_upfront_commitment_for_billing_period"
      type = "double"
    }
    columns {
      name = "savings_plan_recurring_commitment_for_billing_period"
      type = "double"
    }
    columns {
      name = "savings_plan_start_time"
      type = "string"
    }
    columns {
      name = "savings_plan_end_time"
      type = "string"
    }
    columns {
      name = "savings_plan_offering_type"
      type = "string"
    }
    columns {
      name = "savings_plan_payment_option"
      type = "string"
    }
    columns {
      name = "savings_plan_purchase_term"
      type = "string"
    }
    columns {
      name = "savings_plan_region"
      type = "string"
    }
    columns {
      name = "savings_plan_net_savings_plan_effective_cost"
      type = "double"
    }
    columns {
      name = "savings_plan_net_amortized_upfront_commitment_for_billing_period"
      type = "double"
    }
    columns {
      name = "savings_plan_net_recurring_commitment_for_billing_period"
      type = "double"
    }
    columns {
      name = "resource_tags_aws_created_by"
      type = "string"
    }
    columns {
      name = "resource_tags_user_stack"
      type = "string"
    }
    columns {
      name = "resource_tags_user_app_kubernetes_io_name"
      type = "string"
    }
    columns {
      name = "resource_tags_user_application"
      type = "string"
    }
    columns {
      name = "resource_tags_user_business_unit"
      type = "string"
    }
    columns {
      name = "resource_tags_user_component"
      type = "string"
    }
    columns {
      name = "resource_tags_user_eks_cluster_name"
      type = "string"
    }
    columns {
      name = "resource_tags_user_environment_name"
      type = "string"
    }
    columns {
      name = "resource_tags_user_infrastructure_support"
      type = "string"
    }
    columns {
      name = "resource_tags_user_is_production"
      type = "string"
    }
    columns {
      name = "resource_tags_user_namespace"
      type = "string"
    }
    columns {
      name = "resource_tags_user_owner"
      type = "string"
    }
    columns {
      name = "resource_tags_user_runbook"
      type = "string"
    }
    columns {
      name = "resource_tags_user_source_code"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-resource-type"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-jira"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-resource-group"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-name"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-is-backend"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-source"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-is-service-bundle"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-domain-category"
      type = "string"
    }
    columns {
      name = "resource_tags_dpr-domain"
      type = "string"
    }
  }
}
