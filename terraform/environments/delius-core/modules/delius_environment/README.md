# Environment module

This module represents a `delius` environment. It contains all resources scoped to an environment - of which there can be many of in an account.

For examples see:
- `main_development.tf`
- `main_preproduction.tf` - which demonstrates a 2 env account setup

## Pre-Requisites

In order for a new environment block to be created and successfully deployed, the equivalent `locals_<env-name>.tf` needs to be created.

This file contains a number of maps which are called `<component>_config_<env_name>` and get passed into the environment block as `<component>_config`. For example:

```
  ldap_config_dev = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = "479759138745"
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
  }
```

is passed into the dev module call with:
```
  ldap_config = local.ldap_config_dev
```

The following providers block correctly passes the platform provided aws providers to the module.
```
  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
```

The TF Docs below provides reference to all inputs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_aws.core-network-services"></a> [aws.core-network-services](#provider\_aws.core-network-services) | ~> 5.0 |
| <a name="provider_aws.core-vpc"></a> [aws.core-vpc](#provider\_aws.core-vpc) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_linux"></a> [bastion\_linux](#module\_bastion\_linux) | github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux | c918b2189d9f81d224e07e98fa1bc9ff38e4ba12 |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster | v4.3.0 |
| <a name="module_gdpr_api_service"></a> [gdpr\_api\_service](#module\_gdpr\_api\_service) | ../helpers/delius_microservice | n/a |
| <a name="module_gdpr_ui_service"></a> [gdpr\_ui\_service](#module\_gdpr\_ui\_service) | ../helpers/delius_microservice | n/a |
| <a name="module_ip_addresses"></a> [ip\_addresses](#module\_ip\_addresses) | ../../../../modules/ip_addresses | n/a |
| <a name="module_ldap"></a> [ldap](#module\_ldap) | ../components/ldap | n/a |
| <a name="module_merge_api_service"></a> [merge\_api\_service](#module\_merge\_api\_service) | ../helpers/delius_microservice | n/a |
| <a name="module_merge_ui_service"></a> [merge\_ui\_service](#module\_merge\_ui\_service) | ../helpers/delius_microservice | n/a |
| <a name="module_newtech"></a> [newtech](#module\_newtech) | ../helpers/delius_microservice | n/a |
| <a name="module_oracle_db_primary"></a> [oracle\_db\_primary](#module\_oracle\_db\_primary) | ../components/oracle_db_instance | n/a |
| <a name="module_oracle_db_shared"></a> [oracle\_db\_shared](#module\_oracle\_db\_shared) | ../components/oracle_db_shared | n/a |
| <a name="module_oracle_db_standby"></a> [oracle\_db\_standby](#module\_oracle\_db\_standby) | ../components/oracle_db_instance | n/a |
| <a name="module_pagerduty_core_alerts"></a> [pagerduty\_core\_alerts](#module\_pagerduty\_core\_alerts) | github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration | v2.0.0 |
| <a name="module_pdf_creation"></a> [pdf\_creation](#module\_pdf\_creation) | ../helpers/delius_microservice | n/a |
| <a name="module_pwm"></a> [pwm](#module\_pwm) | ../helpers/delius_microservice | n/a |
| <a name="module_s3_bucket_dms_destination"></a> [s3\_bucket\_dms\_destination](#module\_s3\_bucket\_dms\_destination) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | v7.1.0 |
| <a name="module_s3_bucket_ssm_sessions"></a> [s3\_bucket\_ssm\_sessions](#module\_s3\_bucket\_ssm\_sessions) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | v7.1.0 |
| <a name="module_ssm_params_pdf_creation"></a> [ssm\_params\_pdf\_creation](#module\_ssm\_params\_pdf\_creation) | ../helpers/ssm_params | n/a |
| <a name="module_umt"></a> [umt](#module\_umt) | ../helpers/delius_microservice | n/a |
| <a name="module_weblogic"></a> [weblogic](#module\_weblogic) | ../helpers/delius_microservice | n/a |
| <a name="module_weblogic_eis"></a> [weblogic\_eis](#module\_weblogic\_eis) | ../helpers/delius_microservice | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_iam_access_key.pwm_ses_smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_user.pwm_ses_smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.pwm_ses_smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_lb.delius_core_ancillary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.delius_core_frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.ancillary_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.ancillary_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.listener_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.listener_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.allowed_paths_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.blocked_paths_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.homepage_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_route53_record.alb_frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.external_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.external_validation_subdomain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.pwm_amazonses_dkim_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.pwm_amazonses_dmarc_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.pwm_ses_verification_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.delius_core_application_passwords_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_policy.delius_core_application_passwords_pol](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_policy) | resource |
| [aws_security_group.ancillary_alb_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.delius_frontend_alb_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ses_domain_dkim.pwm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim) | resource |
| [aws_ses_domain_identity.pwm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ses_domain_identity_verification.pwm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity_verification) | resource |
| [aws_ses_domain_identity_verification.pwm_ses_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity_verification) | resource |
| [aws_sns_topic.delius_core_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_ssm_parameter.casenotes_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.casenotes_user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_gdpr_api_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_gdpr_db_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_gdpr_db_pool_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_merge_api_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_merge_db_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_merge_db_pool_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_pwm_config_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.delius_core_weblogic_ndelius_domain_umt_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.dss_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.dss_user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.iaps_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.iaps_user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.jdbc_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.jdbc_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.ldap_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.ldap_bind_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.oasys_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.oasys_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.pdfcreation_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.performance_test_user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.pwm_ses_smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.test_user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.usermanagement_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.weblogic_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.weblogic_admin_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.weblogic_eis_google_analytics_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_vpc_security_group_egress_rule.ancillary_alb_egress_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ancillary_alb_ingress_https_global_protect_allowlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.delius_core_frontend_alb_ingress_http_allowlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.delius_core_frontend_alb_ingress_https_allowlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.delius_core_frontend_alb_ingress_https_global_protect_allowlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.db_access_to_secrets_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.delius_core_application_passwords_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.delius_core_frontend_env_var_dev_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.delius_core_frontend_env_var_dev_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.delius_core_merge_api_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.jdbc_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.jdbc_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.pdfcreation_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.usermanagement_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.weblogic_eis_google_analytics_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_config"></a> [account\_config](#input\_account\_config) | n/a | `any` | n/a | yes |
| <a name="input_account_info"></a> [account\_info](#input\_account\_info) | Account level info | `any` | n/a | yes |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | n/a | yes |
| <a name="input_bastion_config"></a> [bastion\_config](#input\_bastion\_config) | n/a | `any` | n/a | yes |
| <a name="input_db_config"></a> [db\_config](#input\_db\_config) | n/a | `any` | n/a | yes |
| <a name="input_db_suffix"></a> [db\_suffix](#input\_db\_suffix) | identifier to append to name e.g. dsd, boe | `string` | `"db"` | no |
| <a name="input_delius_microservice_configs"></a> [delius\_microservice\_configs](#input\_delius\_microservice\_configs) | n/a | `any` | n/a | yes |
| <a name="input_dms_config"></a> [dms\_config](#input\_dms\_config) | n/a | <pre>object({<br>    replication_instance_class = string<br>    engine_version             = string<br>  })</pre> | <pre>{<br>  "engine_version": "3.5.1",<br>  "replication_instance_class": "dms.t3.micro"<br>}</pre> | no |
| <a name="input_enable_platform_backups"></a> [enable\_platform\_backups](#input\_enable\_platform\_backups) | Enable or disable Mod Platform centralised backups | `bool` | `null` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | n/a | `string` | n/a | yes |
| <a name="input_environment_config"></a> [environment\_config](#input\_environment\_config) | n/a | `any` | n/a | yes |
| <a name="input_environments_in_account"></a> [environments\_in\_account](#input\_environments\_in\_account) | n/a | `list(string)` | `[]` | no |
| <a name="input_ignore_changes_service_task_definition"></a> [ignore\_changes\_service\_task\_definition](#input\_ignore\_changes\_service\_task\_definition) | Ignore changes to the task definition | `bool` | `true` | no |
| <a name="input_ldap_config"></a> [ldap\_config](#input\_ldap\_config) | n/a | <pre>object({<br>    name                        = string<br>    encrypted                   = bool<br>    migration_source_account_id = string<br>    migration_lambda_role       = string<br>    efs_throughput_mode         = string<br>    efs_provisioned_throughput  = string<br>    efs_backup_schedule         = string<br>    efs_backup_retention_period = string<br>    port                        = optional(number)<br>  })</pre> | <pre>{<br>  "efs_backup_retention_period": "default_efs_backup_retention_period",<br>  "efs_backup_schedule": "default_efs_backup_schedule",<br>  "efs_provisioned_throughput": "default_efs_provisioned_throughput",<br>  "efs_throughput_mode": "default_efs_throughput_mode",<br>  "encrypted": true,<br>  "migration_lambda_role": "default_migration_lambda_role",<br>  "migration_source_account_id": "default_migration_source_account_id",<br>  "name": "default_name",<br>  "port": 389<br>}</pre> | no |
| <a name="input_pagerduty_integration_key"></a> [pagerduty\_integration\_key](#input\_pagerduty\_integration\_key) | Pager Duty Integration Key | `string` | `null` | no |
| <a name="input_platform_vars"></a> [platform\_vars](#input\_platform\_vars) | n/a | <pre>object({<br>    environment_management = any<br>  })</pre> | n/a | yes |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | SNS topic name | `string` | `"delius-core-alarms-topic"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_domains"></a> [acm\_domains](#output\_acm\_domains) | n/a |
<!-- END_TF_DOCS -->
