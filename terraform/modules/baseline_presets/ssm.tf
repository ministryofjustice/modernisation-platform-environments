locals {

  ssm_schedule_expressions = {
    development = {
      update-ssm-agent-patchgroup1                = "cron(30 7 ? * MON *)"
      update-ssm-agent-patchgroup2                = "cron(30 7 ? * WED *)"
      update-configuration-management-daily       = "cron(00 8 ? * * *)"
      update-configuration-management-patchgroup1 = "cron(00 8 ? * MON *)"
      update-configuration-management-patchgroup2 = "cron(00 8 ? * WED *)"
    }
    test = {
      update-ssm-agent-patchgroup1                = "cron(30 7 ? * MON *)"
      update-ssm-agent-patchgroup2                = "cron(30 7 ? * WED *)"
      update-configuration-management-daily       = "cron(00 8 ? * * *)"
      update-configuration-management-patchgroup1 = "cron(00 8 ? * MON *)"
      update-configuration-management-patchgroup2 = "cron(00 8 ? * WED *)"
    }
    preproduction = {
      update-ssm-agent-patchgroup1                = "cron(00 12 ? * TUE *)"
      update-ssm-agent-patchgroup2                = "cron(00 12 ? * WED *)"
      update-configuration-management-daily       = "cron(30 12 ? * * *)"
      update-configuration-management-patchgroup1 = "cron(30 12 ? * TUE *)"
      update-configuration-management-patchgroup2 = "cron(30 12 ? * WED *)"
    }
    production = {
      update-ssm-agent-patchgroup1                = "cron(00 18 ? * WED *)"
      update-ssm-agent-patchgroup2                = "cron(00 18 ? * THU *)"
      update-configuration-management-daily       = "cron(30 18 ? * * *)"
      update-configuration-management-patchgroup1 = "cron(30 18 ? * WED *)"
      update-configuration-management-patchgroup2 = "cron(30 18 ? * THU *)"
    }
  }

  # the modernisation platform secret 'environment_management' can not be
  # accessed from EC2s. Create a copy as an SSM parameter with just
  # the relevant account ids.
  account_names_for_account_ids_ssm_parameter = distinct(flatten([
    var.options.enable_ec2_delius_dba_secrets_access ? ["delius-core-${var.environment.environment}"] : [],
    var.options.enable_ec2_delius_dba_secrets_access && contains(["development", "preproduction", "production"], var.environment.environment) ? ["delius-mis-${var.environment.environment}"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["hmpps-oem-${var.environment.environment}"] : [],
    var.options.enable_hmpps_domain && contains(["development", "test"], var.environment.environment) ? ["hmpps-domain-services-test"] : [],
    var.options.enable_hmpps_domain && contains(["preproduction", "production"], var.environment.environment) ? ["hmpps-domain-services-production"] : [],
  ]))

  # add a cloud watch windows SSM param if the file is present
  cloud_watch_windows_filename = "./templates/cloud_watch_windows.json"

  ssm_associations_filter = flatten([
    var.options.enable_ec2_ssm_agent_update ? ["AWS-UpdateSSMAgent-patchgroup1"] : [],
    var.options.enable_ec2_ssm_agent_update ? ["AWS-UpdateSSMAgent-patchgroup2"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-windows-daily"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-windows-patchgroup1"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-windows-patchgroup2"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-linux-daily"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-linux-patchgroup1"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-linux-patchgroup2"] : [],
  ])

  ssm_associations = {
    AWS-UpdateSSMAgent-patchgroup1 = {
      apply_only_at_cron_interval = true
      name                        = "AWS-UpdateSSMAgent"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-ssm-agent-patchgroup1
      targets = [
        { key = "tag:update-ssm-agent", values = ["patchgroup1"] },
      ]
    }
    AWS-UpdateSSMAgent-patchgroup2 = {
      apply_only_at_cron_interval = true
      name                        = "AWS-UpdateSSMAgent"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-ssm-agent-patchgroup2
      targets = [
        { key = "tag:update-ssm-agent", values = ["patchgroup2"] },
      ]
    }
    ec2-configuration-management-windows-daily = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-windows"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-daily
      targets = [
        { key = "tag:update-configuration-management", values = ["daily"] },
        { key = "tag:os-type", values = ["Windows"] },
      ]
    }
    ec2-configuration-management-windows-patchgroup1 = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-windows"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-patchgroup1
      targets = [
        { key = "tag:update-configuration-management", values = ["patchgroup1"] },
        { key = "tag:os-type", values = ["Windows"] },
      ]
    }
    ec2-configuration-management-windows-patchgroup2 = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-windows"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-patchgroup2
      targets = [
        { key = "tag:update-configuration-management", values = ["patchgroup2"] },
        { key = "tag:os-type", values = ["Windows"] },
      ]
    }
    ec2-configuration-management-linux-daily = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-linux"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-daily
      targets = [
        { key = "tag:update-configuration-management", values = ["daily"] },
        { key = "tag:os-type", values = ["Linux"] },
      ]
    }
    ec2-configuration-management-linux-patchgroup1 = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-linux"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-patchgroup1
      targets = [
        { key = "tag:update-configuration-management", values = ["patchgroup1"] },
        { key = "tag:os-type", values = ["Linux"] },
      ]
    }
    ec2-configuration-management-linux-patchgroup2 = {
      apply_only_at_cron_interval = true
      name                        = "ec2-configuration-management-linux"
      schedule_expression         = local.ssm_schedule_expressions[var.environment.environment].update-configuration-management-patchgroup2
      targets = [
        { key = "tag:update-configuration-management", values = ["patchgroup2"] },
        { key = "tag:os-type", values = ["Linux"] },
      ]
    }
  }

  ssm_documents_filter = flatten([
    var.options.enable_hmpps_domain ? ["ec2-ad-join-windows"] : [],
    var.options.enable_hmpps_domain ? ["ec2-ad-leave-windows"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-windows"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-configuration-management-linux"] : [],
    var.options.enable_ec2_self_provision ? ["ec2-install-automation-tools-windows"] : [],
    var.options.enable_ec2_session_manager_cloudwatch_logs ? ["SSM-SessionManagerRunShell"] : [],
  ])

  ssm_documents_list = flatten([
    for document_type in ["Command", "Session"] : [
      for document_format in ["yaml", "json"] : [
        for item in fileset("${path.module}/ssm-documents/${document_type}", "*.${document_format}") : {
          key = trimsuffix(item, ".${document_format}")
          value = {
            document_type   = document_type
            document_format = upper(document_format)
            content         = file("${path.module}/ssm-documents/${document_type}/${item}")
          }
        }
      ]
    ]
  ])
  ssm_documents = { for item in local.ssm_documents_list : item.key => item.value }

  ssm_parameters_filter = flatten([
    length(local.account_names_for_account_ids_ssm_parameter) != 0 ? ["account"] : [],
    var.options.enable_azure_sas_token ? ["/azure"] : [],
    var.options.enable_ec2_cloud_watch_agent && fileexists(local.cloud_watch_windows_filename) ? ["cloud-watch-config"] : [],
    try(length(var.options.cloudwatch_metric_oam_links_ssm_parameters), 0) != 0 ? ["/oam"] : [],
    var.options.enable_xsiam_cloudwatch_integration || var.options.enable_xsiam_s3_integration ? ["/xsiam"] : [],
  ])

  ssm_parameters = {

    account = {
      postfix = "_"
      parameters = {
        ids = {
          description = "Selected modernisation platform AWS account IDs managed by baseline module"
          value = jsonencode({
            for key, value in var.environment.account_ids :
            key => value if contains(local.account_names_for_account_ids_ssm_parameter, key)
          })
        }
      }
    }

    "/azure" = {
      parameters = {
        sas_token = { description = "database backup storage account read-only sas token" }
      }
    }

    "/oam" = {
      parameters = {
        for oam_link in coalesce(var.options.cloudwatch_metric_oam_links_ssm_parameters, []) : oam_link => {
          description = "oam sink_identifier to use in aws_oam_link resource"
        }
      }
    }

    "/xsiam" = {
      parameters = merge(
        var.options.enable_xsiam_cloudwatch_integration ? {
          http_endpoint_url = { description = "xsiam http endpoint url, e.g. https://xxx/logs/v1/aws, set outside of terraform" }
        } : {},
        var.options.enable_xsiam_s3_integration ? {
          iam_role_external_id = { description = "external id for IAM role, generated by terraform", uuid = true }
        } : {}
      )
    }

    cloud-watch-config = {
      postfix = "-"
      parameters = {
        windows = {
          description = "cloud watch agent config for windows managed by baseline module"
          file        = local.cloud_watch_windows_filename
          type        = "String"
          tier        = "Advanced"
        }
      }
    }

  }
}

