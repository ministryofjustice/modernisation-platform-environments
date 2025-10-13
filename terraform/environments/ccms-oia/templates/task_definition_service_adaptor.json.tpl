[
  {
    "name": "${adaptor_app_name}-container",
    "image": "${adaptor_ecr_repo}:${container_version}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${adaptor_app_name}-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${adaptor_server_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${adaptor_spring_profile}"
      },
      {
        "name": "CLIENT_OPA12ASSESS_MEANS_ADDRESS",
        "value": "${client_opa12assess_means_address}"
      },
      {
        "name": "CLIENT_OPA12ASSESS_BILLING_ADDRESS",
        "value": "${client_opa12assess_billing_address}"
      },
      {
        "name": "SERVER_OPA10ASSESS_PATH",
        "value": "/opadrulebase"
      },
      {
        "name": "CXF_PATH",
        "value": "/ccms/ws"
      },
      {
        "name": "CCMS_REF-DATA-FILE",
        "value": "reference/opa_entities.csv"
      }
    ],
    "secrets": [
      {
        "name": "CLIENT_OPA12ASSESS_SECURITY_USER_PASSWORD",
        "valueFrom": "${client_opa12assess_security_user_password}"
      },
      {
        "name": "SERVER_OPA10ASSESS_SECURITY_USER_PASSWORD",
        "valueFrom": "${server_opa10assess_security_user_password}"
      },
      {
        "name": "SERVER_OPA10ASSESS_SECURITY_USER_NAME",
        "valueFrom": "${server_opa10assess_security_user_name}"
      },
      {
        "name": "CLIENT_OPA12ASSESS_SECURITY_USER_NAME",
        "valueFrom": "${client_opa12assess_security_user_name}"
      }
    ]
  }
]
