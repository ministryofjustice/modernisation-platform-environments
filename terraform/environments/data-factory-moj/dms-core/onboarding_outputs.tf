locals {
  onboarding_sources = local.dms_core_enabled ? {
    sandbox-postgres = {
      engine             = "postgres"
      database_name      = module.dms_test_harness[0].source_database_name
      secret_ref         = "sandbox-postgres-source"
      secret_arn         = module.dms_test_harness[0].dms_source_secret_arn
      secret_kms_key_arn = module.dms_test_harness[0].dms_source_secret_kms_key_arn
      security_group_id  = module.dms_test_harness[0].dms_client_security_group_id
      bucket_name        = module.dms_test_harness[0].target_bucket_name
      kms_key_arn        = module.dms_test_harness[0].target_kms_key_arn
    }

    sandbox-oracle = {
      engine             = "oracle"
      database_name      = module.oracle_test_harness[0].source_database_name
      secret_ref         = "sandbox-oracle-source"
      secret_arn         = module.oracle_test_harness[0].dms_source_secret_arn
      secret_kms_key_arn = module.oracle_test_harness[0].dms_source_secret_kms_key_arn
      security_group_id  = module.oracle_test_harness[0].dms_client_security_group_id
      bucket_name        = module.oracle_test_harness[0].target_bucket_name
      kms_key_arn        = module.oracle_test_harness[0].target_kms_key_arn
    }
  } : {}
}

output "onboarding_platform_bindings" {
  description = "Development compiler bindings from the existing test harnesses; contains resource identifiers, not credentials."
  sensitive   = true

  value = local.dms_core_enabled ? {
    configuration_version = 1
    environment           = "development"
    region                = data.aws_region.current.region

    services = {
      for name, source in local.onboarding_sources : name => merge(
        {
          engine                       = source.engine
          database_name                = source.database_name
          secret_ref                   = source.secret_ref
          secret_arn                   = source.secret_arn
          secret_kms_key_arn           = source.secret_kms_key_arn
          network_profile              = name
          replication_profile          = "sandbox-small"
          allowed_destination_profiles = [name]
          allowed_concurrency_profiles = ["sandbox-small"]
        },
        source.engine == "postgres" ? {
          ssl_mode = "require"
          } : {
          ssl_mode                    = "none"
          extra_connection_attributes = "useLogminerReader=Y"
        }
      )
    }

    network_profiles = {
      for name, source in local.onboarding_sources : name => {
        vpc_id                        = data.aws_vpc.shared[0].id
        subnet_ids                    = sort(tolist(data.aws_subnets.shared-data[0].ids))
        additional_security_group_ids = [source.security_group_id]
      }
    }

    replication_profiles = {
      sandbox-small = {
        instance_class    = "dms.t3.small"
        allocated_storage = 20
        multi_az          = false
        kms_key_arn       = data.aws_kms_key.general_shared.arn
      }
    }

    destination_profiles = {
      for name, source in local.onboarding_sources : name => {
        parent_domain  = "probation"
        bucket_name    = source.bucket_name
        landing_prefix = "configured-ingestion/"
        kms_key_arn    = source.kms_key_arn
      }
    }

    concurrency_profiles = {
      sandbox-small = {
        max_parallel_tables     = 2
        max_parallel_full_loads = 1
      }
    }

    component_profiles = {
      processing  = ["standard"]
      history     = ["standard"]
      publication = ["sandbox"]
    }
  } : null
}

output "onboarding_source_credentials" {
  description = "Credential preparation settings for new development deployments."
  sensitive   = true

  value = local.dms_core_enabled ? {
    sandbox-postgres = {
      mode              = "synchronise_then_test"
      sync_function_arn = module.dms_test_harness[0].credential_sync_lambda_function_arn
    }

    sandbox-oracle = {
      mode              = "connection_test"
      sync_function_arn = null
    }
  } : null
}

output "onboarding_replication_capacities" {
  description = "Development capacity pools available to configuration-driven ingestion."
  sensitive   = true

  value = local.dms_core_enabled ? {
    sandbox-shared = module.onboarding_replication_capacity[0].binding
  } : null
}
