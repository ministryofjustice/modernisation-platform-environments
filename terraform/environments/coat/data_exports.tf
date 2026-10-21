resource "aws_bcmdataexports_export" "coh_no_ri_sp_export" {
  export {
name        = "COH-No-RI-SP-PARQUET-Export"
    description = "Export Cost Optimization Hub recommendations excluding RI and Savings Plans in PARQUET format"
    
    data_query {
      query_statement = <<EOF
        SELECT *
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