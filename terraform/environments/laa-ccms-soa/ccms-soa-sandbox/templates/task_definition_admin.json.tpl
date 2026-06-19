[
  {
    "name": "${app_name}-admin",
    "image": "${app_image}:${container_version}",
    "stopTimeout": 300,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${app_name}-admin-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${admin_server_port},
        "hostPort": ${admin_server_port}
      },
      {
          "containerPort": ${admin_ssl_port},
          "hostPort": ${admin_ssl_port},
      }
    ],
    "mountPoints": [
        {
            "containerPath": "/u01/oracle/user_projects",
            "sourceVolume": "soa_volume"
        }
    ],
    "environment": [
      {
        "name": "CONNECTION_STRING",
        "value": "${db_instance_endpoint}/SOADB"
      },
      {
        "name": "EBS_DS_URL",
        "value": "${ebs_ds_url}"
      },
        {
        "name": "EBSSMS_DS_URL",
        "value": "${ebssms_ds_url}"
      },
      {
        "name": "XXSOA_DS_URL",
        "value": "${xxsoa_ds_url}"
      },
      {
        "name": "ADMIN_HOST",
        "value": "${as_hostname}"
      },
      {
        "name": "MANAGED_SERVER",
        "value": "soa_server1"
      },
      {
        "name": "DB_USER",
        "value": "${db_user}"
      },
      {
        "name": "XXSOA_DS_USERNAME",
        "value": "${xxsoa_ds_username}"
      },
      {
        "name": "EBS_DS_USERNAME",
        "value": "${ebs_ds_username}"
      },
      {
        "name": "EBSSMS_DS_USERNAME",
        "value": "${ebssms_ds_username}"
      },     
      {
        "name": "CAAB_USER",
        "value": "${caab_user}"
      },
      {
        "name": "PUI_USER",
        "value": "${pui_user}"
      },
      {
        "name": "EBS_USER",
        "value": "${ebs_user_username}"
      },
      {
        "name": "APPLY_USER",
        "value": "${apply_user}"
      },
      {
        "name": "KEYSTORE_SECRET_ID",
        "value": "${keystore_secret_id}"
      },
      {
        "name": "TZ",
        "value": "GB"
      },     
      {
        "name": "EBS_MAX_CAPACITY",
        "value": "150"
      },        
      {
        "name": "RUN_RCU",
        "value": "${run_rcu}"
      },
      {
        "name": "RCUPREFIX",
        "value": "CCMSSOA"
      },    
      {
        "name": "DB_ROLE",
        "value": "${db_role}"
      },     
      {
        "name": "DOMAIN_TYPE",
        "value": "soa"
      },     
      {
        "name": "CONFIG_JVM_ARGS",
        "value": " -Djava.security.egd=file:/tmp/big.random.file"
      },
      {
        "name": "USER_MEM_ARGS",
        "value": "${wl_admin_mem_args} -Djava.security.egd=file:/tmp/big.random.file"
      },      
            
      {
        "name": "EBS_INITIAL_CAPACITY",
        "value": "5"
      },
      {
        "name": "XXSOA_INITIAL_CAPACITY",
        "value": "5"
      },
      {
        "name": "EBSSMS_INITIAL_CAPACITY",
        "value": "0"
      },
      {
        "name": "EBS_CAPACITY_INCREMENT",
        "value": "10"
      }      
    ],
    "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${soa_rds_admin_user_password}"
        },
        {
          "name": "DB_SCHEMA_PASSWORD",
          "valueFrom": "${soa_rds_all_ccmssoa_schema_password}"
        },
        {
          "name": "ADMIN_PASSWORD",
          "valueFrom": "${admin_server_password}"
        },
        {
          "name": "XXSOA_DS_PASSWORD",
          "valueFrom": "${edrms_xxsoa_user_password}"
        },
        {
          "name": "EBS_DS_PASSWORD",
            "valueFrom": "${ccms_apps_user_password}"
        },
        {
          "name": "EBSSMS_DS_PASSWORD",
          "valueFrom": "${cwa_apps_user_password}"
        },
        {
          "name": "PUI_USER_PASSWORD",
          "valueFrom": "${soa_realm_pui_user_password}"
        },
        {
          "name": "APPLY_USER_PASSWORD",
          "valueFrom": "${soa_realm_apply_user_password}"
        },
        {
          "name": "CAAB_USER_PASSWORD",
          "valueFrom": "${soa_realm_caab_user_password}"
        },
          {
          "name": "EBS_USER_PASSWORD",
          "valueFrom": "${soa_realm_ebs_soa_super_user_password}"
        },
        {
          "name": "EXTRA_JAVA_PROPERTIES",
          "valueFrom": "${extra_java_properties}"
        },      
        {
          "name": "KEYSTORE_PASSWORD",
          "valueFrom": "${keystorePassword}"
        },
        {
          "name": "TRUSTSTORE_PASSWORD",
          "valueFrom": "${truststorePassword}"
        }
    ]
  }
]
