provider "awscc" {
  alias  = "bcm_endpoint"
  region = "us-east-1"
}

resource "awscc_bcmdataexports_export" "coh_no_ri_sp_export" {
  provider = awscc.bcm_endpoint

  export = {
    name        = "COH-No-RI-SP-PARQUET-Export"
    description = "Export Cost Optimization Hub recommendations excluding RI and Savings Plans in PARQUET format"

    data_query = {
      query_statement = <<-EOF
        SELECT 
            action_type,
            currency_code,
            current_resource_details,
            current_resource_summary,
            current_resource_type,
            estimated_monthly_cost_after_discount,
            estimated_monthly_cost_before_discount,
            estimated_monthly_savings_after_discount,
            estimated_monthly_savings_before_discount,
            estimated_savings_percentage_after_discount,
            estimated_savings_percentage_before_discount,
            implementation_effort,
            last_refresh_timestamp,
            recommendation_id,
            recommendation_lookback_period_in_days,
            recommendation_source,
            recommended_resource_details,
            recommended_resource_summary,
            recommended_resource_type,
            region,
            restart_needed,
            rollback_possible
        FROM COST_OPTIMIZATION_RECOMMENDATIONS
        WHERE current_resource_type NOT IN (
            'ComputeSavingsPlans',
            'Ec2InstanceSavingsPlans',
            'SageMakerSavingsPlans',
            'DynamoDbReservedCapacity',
            'ElastiCacheReservedInstances',
            'OpenSearchReservedInstances',
            'RdsReservedInstances',
            'RedshiftReservedInstances',
            'Ec2ReservedInstances',
            'MemoryDbReservedInstances'
        )
      EOF

      table_configurations = {
        COST_OPTIMIZATION_RECOMMENDATIONS = {
          INCLUDE_ALL_RECOMMENDATIONS = "FALSE"
        }
      }
    }

    destination_configurations = {
      s3_destination = {
        s3_bucket = "cloud-platform-4e74939a04d400578bfbe3f3f707b07e"
        s3_region = "eu-west-2"
        s3_prefix = "coh-reports-auto/"
        s3_bucket_owner = "754256621582"

        s3_output_configurations = {
          overwrite   = "OVERWRITE_REPORT"
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence = {
      frequency = "SYNCHRONOUS"
    }
  }
}