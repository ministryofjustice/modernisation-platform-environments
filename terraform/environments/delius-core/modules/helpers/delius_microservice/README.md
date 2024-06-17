# Microservices module

This is a 'batteries-included' terraform module that creates an ECS Service (plus the associated resources such as target groups, ALB associations, dns etc).

Optionally, resources such as RDS and elasticache can be deployed.

In addition, this module deploys the baseline monitoring stack for all components and hooks alarms up to pagerduty.

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
| <a name="provider_aws.core-vpc"></a> [aws.core-vpc](#provider\_aws.core-vpc) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container_definition"></a> [container\_definition](#module\_container\_definition) | git::<https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container> | v4.3.0 |
| <a name="module_ecs_policies"></a> [ecs\_policies](#module\_ecs\_policies) | ../ecs_policies | n/a |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | git::<https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service> | v4.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_dashboard.ecs_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.error](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_log_metric_filter.log_error_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.db_connections_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_queue_depth_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_cpu_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.healthy_hosts_fatal_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_error_volume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.log_error_warning_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memory_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ram_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.read_latency_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.response_code_5xx_critical_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.response_code_5xx_warning_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.response_time_critical_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.write_latency_over_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_elasticache_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_iam_role.rds_enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.delius_microservices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.alb_header](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.alb_path](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.alb_r53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.services_nlb_r53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.delius_microservices_service_nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.all_cluster_to_ecs_service_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_to_ecs_service_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ecs_service_tls_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_security_group_egress_rule.custom_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.ecs_service_to_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.nlb_to_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_to_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.custom_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.nlb_to_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_id.rds_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_iam_policy_document.rds_enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_config"></a> [account\_config](#input\_account\_config) | Account config to pass to the instance | `any` | n/a | yes |
| <a name="input_account_info"></a> [account\_info](#input\_account\_info) | Account info to pass to the instance | `any` | n/a | yes |
| <a name="input_alb_listener_rule_host_header"></a> [alb\_listener\_rule\_host\_header](#input\_alb\_listener\_rule\_host\_header) | Host header to use for the alb listener rule | `string` | `null` | no |
| <a name="input_alb_listener_rule_paths"></a> [alb\_listener\_rule\_paths](#input\_alb\_listener\_rule\_paths) | Paths to use for the alb listener rule | `list(string)` | `null` | no |
| <a name="input_alb_listener_rule_priority"></a> [alb\_listener\_rule\_priority](#input\_alb\_listener\_rule\_priority) | Priority of the alb listener | `number` | `null` | no |
| <a name="input_alb_security_group_id"></a> [alb\_security\_group\_id](#input\_alb\_security\_group\_id) | The security group ID of the ALB | `string` | n/a | yes |
| <a name="input_alb_stickiness_enabled"></a> [alb\_stickiness\_enabled](#input\_alb\_stickiness\_enabled) | Enable or disable stickiness | `string` | `true` | no |
| <a name="input_alb_stickiness_type"></a> [alb\_stickiness\_type](#input\_alb\_stickiness\_type) | Type of stickiness for the alb target group | `string` | `"lb_cookie"` | no |
| <a name="input_bastion_sg_id"></a> [bastion\_sg\_id](#input\_bastion\_sg\_id) | Security group id of the bastion | `string` | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | The ARN of the certificate to use for the target group | `string` | n/a | yes |
| <a name="input_cloudwatch_error_pattern"></a> [cloudwatch\_error\_pattern](#input\_cloudwatch\_error\_pattern) | The cloudwatch error pattern to use for the alarm | `string` | `"/error/"` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Security group id for the cluster | `string` | n/a | yes |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | The container cpu to use | `number` | `512` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The container image to use | `string` | n/a | yes |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | The container memory to use | `number` | `1024` | no |
| <a name="input_container_port_config"></a> [container\_port\_config](#input\_container\_port\_config) | The port configuration for the container. First in list is used for Load Balancer Configuration | <pre>list(object({<br>    containerPort = number<br>    protocol      = string<br>  }))</pre> | n/a | yes |
| <a name="input_container_secrets_default"></a> [container\_secrets\_default](#input\_container\_secrets\_default) | Secrets to pass to the container | `map(any)` | n/a | yes |
| <a name="input_container_secrets_env_specific"></a> [container\_secrets\_env\_specific](#input\_container\_secrets\_env\_specific) | Secrets to pass to the container | `map(any)` | n/a | yes |
| <a name="input_container_vars_default"></a> [container\_vars\_default](#input\_container\_vars\_default) | Environment variables to pass to the container | `map(any)` | n/a | yes |
| <a name="input_container_vars_env_specific"></a> [container\_vars\_env\_specific](#input\_container\_vars\_env\_specific) | Environment variables to pass to the container | `map(any)` | n/a | yes |
| <a name="input_create_elasticache"></a> [create\_elasticache](#input\_create\_elasticache) | Whether to create an Elasticache instance | `bool` | `false` | no |
| <a name="input_create_rds"></a> [create\_rds](#input\_create\_rds) | Whether to create an RDS instance | `bool` | `false` | no |
| <a name="input_create_service_nlb"></a> [create\_service\_nlb](#input\_create\_service\_nlb) | Whether to create a service NLB | `bool` | `false` | no |
| <a name="input_db_ingress_security_groups"></a> [db\_ingress\_security\_groups](#input\_db\_ingress\_security\_groups) | Additional RDS/elasticache ingress security groups | `list(string)` | n/a | yes |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment | `number` | `100` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment | `number` | `0` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The desired count of the service | `number` | `1` | no |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | The ARN of the ECS cluster | `string` | n/a | yes |
| <a name="input_ecs_service_egress_security_group_ids"></a> [ecs\_service\_egress\_security\_group\_ids](#input\_ecs\_service\_egress\_security\_group\_ids) | Security group ids to allow egress from the ECS service | <pre>list(object({<br>    referenced_security_group_id = optional(string, null)<br>    cidr_ipv4                    = optional(string, null)<br>    port                         = optional(number, null)<br>    ip_protocol                  = string<br>  }))</pre> | `[]` | no |
| <a name="input_ecs_service_ingress_security_group_ids"></a> [ecs\_service\_ingress\_security\_group\_ids](#input\_ecs\_service\_ingress\_security\_group\_ids) | Security group ids to allow ingress to the ECS service | <pre>list(object({<br>    referenced_security_group_id = optional(string, null)<br>    cidr_ipv4                    = optional(string, null)<br>    port                         = number<br>    ip_protocol                  = string<br>  }))</pre> | `[]` | no |
| <a name="input_efs_volumes"></a> [efs\_volumes](#input\_efs\_volumes) | The EFS volumes to mount | `list(any)` | `[]` | no |
| <a name="input_elasticache_apply_immediately"></a> [elasticache\_apply\_immediately](#input\_elasticache\_apply\_immediately) | Apply changes immediately | `bool` | `false` | no |
| <a name="input_elasticache_endpoint_environment_variable"></a> [elasticache\_endpoint\_environment\_variable](#input\_elasticache\_endpoint\_environment\_variable) | Environment variable to store the elasticache endpoint | `string` | `""` | no |
| <a name="input_elasticache_engine"></a> [elasticache\_engine](#input\_elasticache\_engine) | The Elasticache engine | `string` | `"redis"` | no |
| <a name="input_elasticache_engine_version"></a> [elasticache\_engine\_version](#input\_elasticache\_engine\_version) | The Elasticache engine version | `string` | `"5.0.6"` | no |
| <a name="input_elasticache_node_type"></a> [elasticache\_node\_type](#input\_elasticache\_node\_type) | The Elasticache node type | `string` | `"cache.m4.large"` | no |
| <a name="input_elasticache_num_cache_nodes"></a> [elasticache\_num\_cache\_nodes](#input\_elasticache\_num\_cache\_nodes) | The Elasticache number of cache nodes | `number` | `1` | no |
| <a name="input_elasticache_parameter_group_family"></a> [elasticache\_parameter\_group\_family](#input\_elasticache\_parameter\_group\_family) | The Elasticache parameter group family | `string` | `"redis5.0"` | no |
| <a name="input_elasticache_parameter_group_name"></a> [elasticache\_parameter\_group\_name](#input\_elasticache\_parameter\_group\_name) | The Elasticache parameter group name | `string` | `"default.redis5.0"` | no |
| <a name="input_elasticache_parameters"></a> [elasticache\_parameters](#input\_elasticache\_parameters) | A map of elasticache parameter names & values | `map(string)` | `{}` | no |
| <a name="input_elasticache_port"></a> [elasticache\_port](#input\_elasticache\_port) | The Elasticache port | `number` | `6379` | no |
| <a name="input_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#input\_elasticache\_subnet\_group\_name) | The Elasticache subnet group name | `string` | `"default"` | no |
| <a name="input_enable_platform_backups"></a> [enable\_platform\_backups](#input\_enable\_platform\_backups) | Enable or disable Mod Platform centralised backups | `bool` | `null` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name short ie dev | `string` | n/a | yes |
| <a name="input_extra_task_role_policies"></a> [extra\_task\_role\_policies](#input\_extra\_task\_role\_policies) | A map of data "aws\_iam\_policy\_document" objects, keyed by name, to attach to the task role | `map(any)` | `{}` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Force a new deployment | `bool` | `false` | no |
| <a name="input_frontend_lb_arn_suffix"></a> [frontend\_lb\_arn\_suffix](#input\_frontend\_lb\_arn\_suffix) | Used by alarms | `string` | n/a | yes |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | The amount of time, in seconds, that Amazon ECS waits before unhealthy instances are shut down. | `number` | `60` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | The health check interval for the alb target group | `string` | `"300"` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | The health check path for the alb target group | `string` | n/a | yes |
| <a name="input_ignore_changes_service_task_definition"></a> [ignore\_changes\_service\_task\_definition](#input\_ignore\_changes\_service\_task\_definition) | Ignore changes to the task definition | `bool` | `true` | no |
| <a name="input_log_error_pattern"></a> [log\_error\_pattern](#input\_log\_error\_pattern) | Used by metric filter for error count | `string` | n/a | yes |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | RDS/elasticache maintenance window | `string` | `"Wed:21:00-Wed:23:00"` | no |
| <a name="input_microservice_lb"></a> [microservice\_lb](#input\_microservice\_lb) | load balancer to use for the target group | `any` | n/a | yes |
| <a name="input_microservice_lb_https_listener_arn"></a> [microservice\_lb\_https\_listener\_arn](#input\_microservice\_lb\_https\_listener\_arn) | The ARN of the load balancer HTTPS listener to use for the target group | `string` | `null` | no |
| <a name="input_mount_points"></a> [mount\_points](#input\_mount\_points) | The mount points for the EFS volumes | `list(any)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the application | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the application | `string` | `"delius-core"` | no |
| <a name="input_platform_vars"></a> [platform\_vars](#input\_platform\_vars) | n/a | <pre>object({<br>    environment_management = any<br>  })</pre> | n/a | yes |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | RDS allocated storage | `number` | `null` | no |
| <a name="input_rds_allow_major_version_upgrade"></a> [rds\_allow\_major\_version\_upgrade](#input\_rds\_allow\_major\_version\_upgrade) | RDS allow major version upgrade | `bool` | `false` | no |
| <a name="input_rds_apply_immediately"></a> [rds\_apply\_immediately](#input\_rds\_apply\_immediately) | RDS apply immediately | `bool` | `false` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | RDS backup retention period | `number` | `1` | no |
| <a name="input_rds_backup_window"></a> [rds\_backup\_window](#input\_rds\_backup\_window) | RDS backup window | `string` | `"19:00-21:00"` | no |
| <a name="input_rds_delete_automated_backups"></a> [rds\_delete\_automated\_backups](#input\_rds\_delete\_automated\_backups) | RDS delete automated backups | `bool` | `false` | no |
| <a name="input_rds_deletion_protection"></a> [rds\_deletion\_protection](#input\_rds\_deletion\_protection) | RDS deletion protection | `bool` | `false` | no |
| <a name="input_rds_enabled_cloudwatch_logs_exports"></a> [rds\_enabled\_cloudwatch\_logs\_exports](#input\_rds\_enabled\_cloudwatch\_logs\_exports) | RDS enabled cloudwatch logs exports | `list(string)` | `null` | no |
| <a name="input_rds_endpoint_environment_variable"></a> [rds\_endpoint\_environment\_variable](#input\_rds\_endpoint\_environment\_variable) | Environment variable to store the RDS endpoint | `string` | `""` | no |
| <a name="input_rds_engine"></a> [rds\_engine](#input\_rds\_engine) | RDS engine to use | `string` | `null` | no |
| <a name="input_rds_engine_version"></a> [rds\_engine\_version](#input\_rds\_engine\_version) | RDS engine version to use | `string` | `null` | no |
| <a name="input_rds_iam_database_authentication_enabled"></a> [rds\_iam\_database\_authentication\_enabled](#input\_rds\_iam\_database\_authentication\_enabled) | RDS iam database authentication enabled | `bool` | `false` | no |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | RDS instance class to use | `string` | `null` | no |
| <a name="input_rds_license_model"></a> [rds\_license\_model](#input\_rds\_license\_model) | RDS license model to use | `string` | `"license-included"` | no |
| <a name="input_rds_max_allocated_storage"></a> [rds\_max\_allocated\_storage](#input\_rds\_max\_allocated\_storage) | RDS allocated storage | `number` | `null` | no |
| <a name="input_rds_monitoring_interval"></a> [rds\_monitoring\_interval](#input\_rds\_monitoring\_interval) | RDS monitoring interval | `number` | `60` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | RDS multi az | `bool` | `false` | no |
| <a name="input_rds_parameter_group_name"></a> [rds\_parameter\_group\_name](#input\_rds\_parameter\_group\_name) | RDS parameter group name | `string` | `null` | no |
| <a name="input_rds_password_secret_variable"></a> [rds\_password\_secret\_variable](#input\_rds\_password\_secret\_variable) | Secret variable to store the rds secretsmanager arn password | `string` | `""` | no |
| <a name="input_rds_performance_insights_enabled"></a> [rds\_performance\_insights\_enabled](#input\_rds\_performance\_insights\_enabled) | RDS performance insights enabled | `bool` | `false` | no |
| <a name="input_rds_port"></a> [rds\_port](#input\_rds\_port) | RDS port | `number` | `null` | no |
| <a name="input_rds_skip_final_snapshot"></a> [rds\_skip\_final\_snapshot](#input\_rds\_skip\_final\_snapshot) | RDS skip final snapshot | `bool` | `false` | no |
| <a name="input_rds_storage_type"></a> [rds\_storage\_type](#input\_rds\_storage\_type) | RDS storage type | `string` | `"gp2"` | no |
| <a name="input_rds_user_secret_variable"></a> [rds\_user\_secret\_variable](#input\_rds\_user\_secret\_variable) | Secret variable to store the rds secretsmanager arn username | `string` | `""` | no |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | RDS database username | `string` | `null` | no |
| <a name="input_redeploy_on_apply"></a> [redeploy\_on\_apply](#input\_redeploy\_on\_apply) | Redeploy the ecs service on apply | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | RDS snapshot identifier | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Used by alarms | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the instance | `map(string)` | n/a | yes |
| <a name="input_target_group_protocol"></a> [target\_group\_protocol](#input\_target\_group\_protocol) | The protocol to use for the target group | `string` | `"HTTP"` | no |
| <a name="input_target_group_protocol_version"></a> [target\_group\_protocol\_version](#input\_target\_group\_protocol\_version) | The version of the protocol to use for the target group | `string` | `"HTTP2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_elasticache_endpoint"></a> [elasticache\_endpoint](#output\_elasticache\_endpoint) | n/a |
| <a name="output_elasticache_port"></a> [elasticache\_port](#output\_elasticache\_port) | n/a |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | n/a |
| <a name="output_rds_password_secret_arn"></a> [rds\_password\_secret\_arn](#output\_rds\_password\_secret\_arn) | n/a |
| <a name="output_rds_port"></a> [rds\_port](#output\_rds\_port) | n/a |
| <a name="output_service_security_group_id"></a> [service\_security\_group\_id](#output\_service\_security\_group\_id) | n/a |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | n/a |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
