[
  {
    "name": "${app_name}-admin",
    "image": "${app_image}:${container_version}",
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
        "name": "RUN_RCU",
        "value": "${run_rcu}"
      },
      {
        "name": "RCUPREFIX",
        "value": "CCMSSOA"
      },
      {
        "name": "DB_USER",
        "value": "${db_user}"
      },
      {
        "name": "DB_ROLE",
        "value": "${db_role}"
      },
      {
        "name": "MANAGED_SERVER",
        "value": "soa_server1"
      },
      {
        "name": "DOMAIN_TYPE",
        "value": "soa"
      },
      {
        "name": "ADMIN_HOST",
        "value": "${as_hostname}"
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
        "name": "XXSOA_DS_URL",
        "value": "${xxsoa_ds_url}"
      },
      {
        "name": "XXSOA_DS_USERNAME",
        "value": "${xxsoa_ds_username}"
      },
      {
        "name": "EBS_DS_URL",
        "value": "${ebs_ds_url}"
      },
      {
        "name": "EBS_DS_USERNAME",
        "value": "${ebs_ds_username}"
      },
      {
        "name": "EBSSMS_DS_URL",
        "value": "${ebssms_ds_url}"
      },
      {
        "name": "EBSSMS_DS_USERNAME",
        "value": "${ebssms_ds_username}"
      },
      {
        "name": "EBS_MAX_CAPACITY",
        "value": "150"
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
      },
      {
        "name": "PUI_USER",
        "value": "pui_user"
      },
      {
        "name": "EBS_USER",
        "value": "${ebs_user_username}"
      },
      {
        "name": "TZ",
        "value": "GB"
      }
    ],
    "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${soa_password}"
        },
        {
          "name": "DB_SCHEMA_PASSWORD",
          "valueFrom": "${soa_password}"
        },
        {
          "name": "ADMIN_PASSWORD",
          "valueFrom": "${soa_password}"
        },
        {
          "name": "XXSOA_DS_PASSWORD",
          "valueFrom": "${xxsoa_ds_password}"
        },
        {
          "name": "EBS_DS_PASSWORD",
            "valueFrom": "${ebs_ds_password}"
        },
        {
          "name": "EBSSMS_DS_PASSWORD",
          "valueFrom": "${ebssms_ds_password}"
        },
        {
          "name": "PUI_USER_PASSWORD",
          "valueFrom": "${pui_user_password}"
        },
        {
          "name": "EBS_USER_PASSWORD",
          "valueFrom": "${ebs_user_password}"
        },
        {
          "name": "EXTRA_JAVA_PROPERTIES",
          "valueFrom": "${trust_store_password}"
        }
    ]
  }
]
