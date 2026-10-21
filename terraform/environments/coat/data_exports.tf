resource "aws_bcmdataexports_export" "coh_no_ri_sp_export" {
  export {
    name        = "COH-No-RI-SP-CSV-Export"
    description = "Export Cost Optimization Hub recommendations excluding RI and Savings Plans in CSV format"
    
    data_query {
      query_statement = <<EOF
        SELECT 
            estimated_monthly_savings
            account_id
            account_name
            region
            current_resource_type
            resource_id
            action_type
            current_resource_summary
            recommended_resource_summary
            estimated_monthly_cost
            estimated_savings_percentage
            last_refresh_timestamp
            recommendation_id
            implementation_effort
            tags
            restart_needed
            rollback_possible
            recommendation_lookback_period_in_days
            source
            currency_code
            recommended_resource_type
            resource_arn
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

    destination_configurations {
      s3_destination {
        s3_bucket       = "cloud-platform-4e74939a04d400578bfbe3f3f707b07e"
        s3_region       = "eu-west-2"
        s3_prefix       = "coh-reports-auto/"

        s3_output_configurations {
          overwrite   = "OVERWRITE_REPORT"
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }
}