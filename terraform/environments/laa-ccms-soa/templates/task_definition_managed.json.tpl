[
  {
    "name": "${app_name}-managed",
    "image": "${app_image}:${container_version}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${app_name}-managed-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${managed_server_port},
        "hostPort": ${managed_server_port}
      },
      {
        "containerPort": 7574,
        "hostPort": 7574
      },
      {
        "containerPort": 7,
        "hostPort": 7
      },
      {
        "containerPort": 8088,
        "hostPort": 8088
      },
      {
        "containerPort": 8089,
        "hostPort": 8089
      }
    ],
    "mountPoints": [
      {
          "containerPath": "/u01/oracle/user_projects",
          "sourceVolume": "soa_volume"
      },
      {
          "containerPath": "/u03/oracle/fileops/inbound",
          "sourceVolume": "inbound_volume"
      },
      {
          "containerPath": "/u03/oracle/fileops/outbound",
          "sourceVolume": "outbound_volume"
      }
    ],
    "environment": [
      {
        "name": "ADMIN_HOST",
        "value": "${admin_host}"
      },
      {
        "name": "ADMIN_PORT",
        "value": "${admin_server_port}"
      },
      {
        "name": "MANAGED_SERVER",
        "value": "soa_server1"
      },
      {
        "name": "adminhostname",
        "value": "${admin_host}"
      },
      {
        "name": "adminport",
        "value": "${admin_server_port}"
      },      
      {
        "name": "DOMAIN_TYPE",
        "value": "soa"
      },
      {
        "name": "DOMAIN_NAME",
        "value": "soainfra"
      },
      {
        "name": "DOMAIN_ROOT",
        "value": "/u01/oracle/user_projects/domains"
      },      
      {
        "name": "MANAGED_HOST",
        "value": "${ms_hostname}"
      },
      {
        "name": "MS_PORT",
        "value": "${managed_server_port}"
      },
      {
        "name": "CLUSTER_NAME",
        "value": "ccms_soa_cluster"
      },
      {
        "name": "USER_MEM_ARGS",
        "value": "${wl_mem_args}"
      },
      {
        "name": "JAVA_OPTION",
        "value": "-Djava.security.egd=file:/dev/./urandom"
      },
      {
        "name": "TZ",
        "value": "GB"
      }
    ],
    "secrets": [
        {
          "name": "ADMIN_PASSWORD",
          "valueFrom": "${soa_password}"
        },
        {
          "name": "EXTRA_JAVA_PROPERTIES",
          "valueFrom": "${trust_store_password}"
        }
    ]
  }
]
