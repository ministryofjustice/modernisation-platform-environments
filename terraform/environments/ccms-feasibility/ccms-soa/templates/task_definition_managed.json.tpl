[
  {
    "name": "${app_name}-managed",
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
        "containerPort": ${managed_ssl_port},
        "hostPort": ${managed_ssl_port}
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
      { "name": "ADMIN_HOST", "value": "${admin_host}" },
      { "name": "ADMIN_PORT", "value": "${admin_ssl_port}" },
      { "name": "MANAGED_SERVER", "value": "soa_server1" },
      { "name": "adminhostname", "value": "${admin_host}" },
      { "name": "adminport", "value": "${admin_ssl_port}" },
      { "name": "DOMAIN_TYPE", "value": "soa" },
      { "name": "DOMAIN_NAME", "value": "soainfra" },
      { "name": "DOMAIN_ROOT", "value": "/u01/oracle/user_projects/domains" },
      { "name": "MANAGED_HOST", "value": "${ms_hostname}" },
      { "name": "MS_PORT", "value": "${managed_ssl_port}" },
      { "name": "CLUSTER_NAME", "value": "ccms_soa_cluster" },
      { "name": "USER_MEM_ARGS", "value": "${wl_mem_args}" },
      { "name": "JAVA_OPTION", "value": "-Djava.security.egd=file:/dev/./urandom" },
      { "name": "TZ", "value": "GB" }
    ],
    "secrets": [
      { "name": "ADMIN_PASSWORD", "valueFrom": "${soa_secret_arn}:admin_server_password::" },
      { "name": "EXTRA_JAVA_PROPERTIES", "valueFrom": "${soa_secret_arn}:extra_java_properties::" },
      { "name": "KEYSTORE_PASSWORD", "valueFrom": "${soa_secret_arn}:keystorePassword::" },
      { "name": "TRUSTSTORE_PASSWORD", "valueFrom": "${soa_secret_arn}:truststorePassword::" },
      { "name": "SLACK_CHANNEL_WEBHOOK", "valueFrom": "${soa_secret_arn}:slack_channel_webhook::" }
    ]
  }
]
