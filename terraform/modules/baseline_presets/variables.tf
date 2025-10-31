# tflint-ignore: terraform_typed_variables
variable "environment" {
  # Not defining 'type' as it is defined in the output of the environment module
  description = "Standard environmental data resources from the environment module"
}

# tflint-ignore: terraform_typed_variables
variable "ip_addresses" {
  # Not defining 'type' as it is defined in the output of the ip_addresses module
  description = "ip address resources from the ip_address module"
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    backup_plan_daily_delete_after               = optional(number, 7)             # override retention for daily + weekly backup plan
    backup_plan_weekly_delete_after              = optional(number, 28)            # override retention for daily + weekly backup plan
    cloudwatch_dashboard_default_widget_groups   = optional(list(string))          # create Cloudwatch-Default dashboard; list of map keys to filter local.cloudwatch_dashboard_widget_groups
    cloudwatch_log_groups_retention_in_days      = optional(number)                # number of days to retain cloudwatch log groups, retention is environment specific, so will be determined in locals.
    cloudwatch_metric_alarms_default_actions     = optional(list(string))          # default alarm_action to apply to cloudwatch metrics returned by this module
    cloudwatch_metric_oam_links_ssm_parameters   = optional(list(string))          # list of account names to send cloudwatch metrics to, creates placeholder SSM param for each
    cloudwatch_metric_oam_links                  = optional(list(string))          # list of account names to send cloudwatch metrics to, creates oam link for each
    db_backup_bucket_name                        = optional(string)                # override default backup bucket name
    db_backup_lifecycle_rule                     = optional(string)                # override default backup bucket lifecycle
    db_backup_more_permissions                   = optional(bool, false)           # allow cross-account delete access for db-backup S3 buckets
    enable_application_environment_wildcard_cert = optional(bool, false)           # create ACM cert with mod platform business unit
    enable_azure_sas_token                       = optional(bool, false)           # create /azure SSM parameter and pipeline role
    enable_backup_plan_daily_and_weekly          = optional(bool, false)           # create backup plan with daily + weekly backups
    enable_business_unit_kms_cmks                = optional(bool, false)           # create grant + policies for business unit KMS access
    enable_hmpps_domain                          = optional(bool, false)           # create policy for accessing secrets in hmpps-domain account
    enable_image_builder                         = optional(bool, false)           # create role and policies for accessing AMIs in core-shared-services-production
    enable_ec2_cloud_watch_agent                 = optional(bool, false)           # create EC2 policy for cloudwatch agent
    enable_ec2_delius_dba_secrets_access         = optional(bool, false)           # create role for accessing secrets in delius account
    enable_ec2_security_groups                   = optional(bool, false)           # create default security groups for EC2s
    enable_ec2_self_provision                    = optional(bool, false)           # create EC2 policy for ansible provisioning
    enable_ec2_reduced_ssm_policy                = optional(bool, false)           # create standard AWS SSM policy minus ssm:GetParameter
    enable_ec2_oracle_enterprise_managed_server  = optional(bool, false)           # create role for accessing secrets in hmpps-oem accounts
    enable_ec2_session_manager_cloudwatch_logs   = optional(bool, false)           # create SSM doc and log group for session manager logs
    enable_ec2_ssm_agent_update                  = optional(bool, false)           # create SSM association for auto-update of SSM agent. update-ssm-agent tag needs to be set on EC2s also
    enable_ec2_user_keypair                      = optional(bool, false)           # create secret and key-pair for ec2-user
    enable_s3_bucket                             = optional(bool, false)           # create s3-bucket S3 bucket for general use
    enable_s3_db_backup_bucket                   = optional(bool, false)           # create db-backup S3 buckets
    enable_s3_shared_bucket                      = optional(bool, false)           # create devtest and preprodprod S3 bucket for sharing between accounts
    enable_s3_software_bucket                    = optional(bool, false)           # create software S3 bucket in test account for image builder/configuration-management
    enable_ssm_command_monitoring                = optional(bool, false)           # create SNS topic and alarms for SSM command monitoring
    enable_ssm_missing_metric_monitoring         = optional(bool, false)           # create alarm if SSM command metrics are missing
    enable_vmimport                              = optional(bool, false)           # create role for vm imports
    enable_xsiam_cloudwatch_integration          = optional(bool, false)           # create data_firehose for cloudwatch groups for xsiam
    enable_xsiam_s3_integration                  = optional(bool, false)           # create IAM role and policy for xsiam for S3 log collection
    route53_resolver_rules                       = optional(map(list(string)), {}) # create route53 resolver rules; list of map keys to filter local.route53_resolver_rules_all
    iam_service_linked_roles                     = optional(list(string))          # create iam service linked roles; list of map keys to filter local.iam_service_linked_roles; default is to create all
    s3_bucket_name                               = optional(string)                # override default general purpose bucket name
    s3_iam_policies                              = optional(list(string))          # create default iam policies for bucket access, list of map keys to filter local.s3_iam_policies
    software_bucket_name                         = optional(string)                # override default software/artefacts bucket name

    sns_topics = optional(object({
      pagerduty_integrations = optional(map(string), {}) # create sns topics where map key is name and value is modernisation platform pagerduty_integration_keys
      }), {
      pagerduty_integrations = {}
    })
  })
}
