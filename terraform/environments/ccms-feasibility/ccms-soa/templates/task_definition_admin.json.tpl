[
  {
    "name": "${app_name}-admin",
    "image": "${app_image}:${container_version}",
    "stopTimeout": 300,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": ${admin_ssl_port},
        "hostPort": ${admin_ssl_port}
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/u01/oracle/user_projects",
        "sourceVolume": "soa_volume"
      }
    ],
    "environment": [
      { "name": "CONNECTION_STRING", "value": "${db_instance_endpoint}/SOADB" },
      { "name": "RUN_RCU", "value": "${run_rcu}" },
      { "name": "RCUPREFIX", "value": "CCMSSOA" },
      { "name": "DB_USER", "value": "${db_user}" },
      { "name": "DB_ROLE", "value": "${db_role}" },
      { "name": "MANAGED_SERVER", "value": "soa_server1" },
      { "name": "DOMAIN_TYPE", "value": "soa" },
      { "name": "ADMIN_HOST", "value": "${as_hostname}" },
      { "name": "USER_MEM_ARGS", "value": "${wl_admin_mem_args} -Djava.security.egd=file:/tmp/big.random.file" },
      { "name": "XXSOA_DS_URL", "value": "${xxsoa_ds_url}" },
      { "name": "XXSOA_DS_USERNAME", "value": "${xxsoa_ds_username}" },
      { "name": "PUI_USER", "value": "${pui_user}" },
      { "name": "CAAB_USER", "value": "${caab_user}" },
      { "name": "APPLY_USER", "value": "${apply_user}" },
      { "name": "KEYSTORE_SECRET_ID", "value": "${keystore_secret_id}" },
      { "name": "TZ", "value": "GB" }
    ],
    "secrets": [
      { "name": "DB_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_rds_admin_user_password::" },
      { "name": "DB_SCHEMA_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_rds_all_ccmssoa_schema_password::" },
      { "name": "ADMIN_PASSWORD", "valueFrom": "${soa_secret_arn}:admin_server_password::" },
      { "name": "EBS_DS_URL", "valueFrom": "${soa_secret_arn}:admin_ebs_ds_url::" },
      { "name": "EBS_DS_USERNAME", "valueFrom": "${soa_secret_arn}:admin_ebs_ds_username::" },
      { "name": "EBSSMS_DS_URL", "valueFrom": "${soa_secret_arn}:admin_ebssms_ds_url::" },
      { "name": "EBSSMS_DS_USERNAME", "valueFrom": "${soa_secret_arn}:admin_ebssms_ds_username::" },
      { "name": "EBS_USER", "valueFrom": "${soa_secret_arn}:admin_ebs_user_username::" },
      { "name": "XXSOA_DS_PASSWORD", "valueFrom": "${soa_secret_arn}:edrms_xxsoa_user_password::" },
      { "name": "EBS_DS_PASSWORD", "valueFrom": "${soa_secret_arn}:ccms_apps_user_password::" },
      { "name": "EBSSMS_DS_PASSWORD", "valueFrom": "${soa_secret_arn}:cwa_apps_user_password::" },
      { "name": "PUI_USER_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_realm_pui_user_password::" },
      { "name": "APPLY_USER_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_realm_apply_user_password::" },
      { "name": "CAAB_USER_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_realm_caab_user_password::" },
      { "name": "EBS_USER_PASSWORD", "valueFrom": "${soa_secret_arn}:soa_realm_ebs_soa_super_user_password::" },
      { "name": "EXTRA_JAVA_PROPERTIES", "valueFrom": "${soa_secret_arn}:extra_java_properties::" },
      { "name": "KEYSTORE_PASSWORD", "valueFrom": "${soa_secret_arn}:keystorePassword::" },
      { "name": "TRUSTSTORE_PASSWORD", "valueFrom": "${soa_secret_arn}:truststorePassword::" },
      { "name": "SLACK_CHANNEL_WEBHOOK", "valueFrom": "${soa_secret_arn}:slack_channel_webhook::" }
    ]
  }
]
