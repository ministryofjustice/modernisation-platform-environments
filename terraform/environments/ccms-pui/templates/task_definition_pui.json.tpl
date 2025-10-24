[
  {
    "name": "${app_name}",
    "image": "${app_image}:${container_version}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${app_name}-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${pui_server_port},
        "hostPort": ${pui_server_port}
      }
    ],
    "environment": [
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${spring_profiles_active}"
      },
      {
        "name": "SPRING_DATASOURCE_HIKARI_KEEPALIVE-TIME",
        "value": "60000"
      },
      {
        "name": "SERVER_FORWARD_HEADERS_STRATEGY",
        "value": "framework"
      },
      {
        "name": "ENTRA_CUSTOM_USER_ID_CLAIM",
        "value": "${entra_custom_user_id_claim}"
      },
      {
        "name": "IS_SILAS_ENABLED",
        "value": "${is_silas_enabled}"
      },
      {
        "name": "IDPLOGOUTURL",
        "value": "${idpLogoutUrl}"
      },
      {
        "name": "IDPSAMLMOCKENABLED",
        "value": "${IdpSamlMockEnabled}"
      },
      {
        "name": "CCMS_S3_DOCUMENTS",
        "value": "${ccms_s3_documents}"
      },
      {
        "name": "AWS_ENDPOINT",
        "value": "${aws_endpoint}"
      },
      {
        "name": "ccms_pui_feedback_url",
        "value": "${ccms_pui_feedback_url}"
      },
      {
        "name": "ccms_pui_owd_return_url",
        "value": "${ccms_pui_owd_return_url}"
      },
      {
        "name": "ccms_soa_url_opaBillingAssessmentEndpoint",
        "value": "${ccms_soa_url_opaBillingAssessmentEndpoint}"
      },
      {
        "name": "ccms_soa_url_opaPOAAssessmentEndpoint",
        "value": "${ccms_soa_url_opaPOAAssessmentEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsClientEndpoint",
        "value": "${ccms_soa_url_ebsClientEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCaseEndpoint",
        "value": "${ccms_soa_url_ebsCaseEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsAddressEndpoint",
        "value": "${ccms_soa_url_ebsAddressEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsReferenceDataEndpoint",
        "value": "${ccms_soa_url_ebsReferenceDataEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsContractDetailsEndpoint",
        "value": "${ccms_soa_url_ebsContractDetailsEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsProviderRequestEndpoint",
        "value": "${ccms_soa_url_ebsProviderRequestEndpoint}"
      },
            {
        "name": "ccms_soa_url_ebsStatementOfAccountEndpoint",
        "value": "${ccms_soa_url_ebsStatementOfAccountEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsNotificationEndpoint",
        "value": "${ccms_soa_url_ebsNotificationEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsDocumentEndpoint",
        "value": "${ccms_soa_url_ebsDocumentEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCreateInvoiceEndpoint",
        "value": "${ccms_soa_url_ebsCreateInvoiceEndpoint}"
      },
            {
        "name": "ccms_soa_url_ebsCoverSheetEndpoint",
        "value": "${ccms_soa_url_ebsCoverSheetEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCommonOrgEndpoint",
        "value": "${ccms_soa_url_ebsCommonOrgEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsPrintInvoiceEndpoint",
        "value": "${ccms_soa_url_ebsPrintInvoiceEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsGetInvoiceDetailsEndpoint",
        "value": "${ccms_soa_url_ebsGetInvoiceDetailsEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsUpdateUserEndpoint",
        "value": "${ccms_soa_url_ebsUpdateUserEndpoint}"
      },
      {
        "name": "opa12_assess_service_servlet",
        "value": "${opa12_assess_service_servlet}"
      },
      {
        "name": "ccms_owd_rulebase_baseurl",
        "value": "${ccms_owd_rulebase_baseurl}"
      },
      {
        "name": "CCMS_PUI_AV_PORT",
        "value": "${ccms_pui_av_port}"
      },
      {
        "name": "CCMS_PUI_AV_HOST",
        "value": "${ccms_pui_av_host}"
      },
      {
        "name": "CCMS_PUI_AV_SOCKETTIMEOUT",
        "value": "${ccms_pui_av_socketTimeout}"
      },
      {
        "name": "CCMS_PUI_AV_SCANNERENABLED",
        "value": "${ccms_pui_av_scannerEnabled}"
      },
      {
        "name": "CCMS_PUI_AUDITLOGIN_ENABLED",
        "value": "${ccms_pui_auditLogin_enabled}"
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "value": "${logging_level_root}"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV",
        "value": "${logging_level_com_ezgov}"
      },
      {
        "name": "LOGGING_LEVEL_COM_LEGALSERVICES",
        "value": "${logging_level_com_legalservices}"
      },
      {
        "name": "LOGGING_LEVEL_UK_GOV_LAA_OPA",
        "value": "${logging_level_uk_gov_laa_opa}"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV_ROOF_VIEW_VIM_CONTROL_BUNDLEAWARETEXT",
        "value": "${logging_level_com_ezgov_roof_view_vim_control_BundleAwareText}"
      }
    ],
    "secrets": [
      {
        "name": "IDPCERT",
        "valueFrom": "${idp_cert}"
      },
      {
        "name": "SPCERT",
        "valueFrom": "${spcert}"
      },
      {
        "name": "SPPRIVATEKEY",
        "valueFrom": "${spprivatekey}"
      },
      {
        "name": "SPRING_DATASOURCE_PASSWORD",
        "valueFrom": "${spring_datasource_password}"
      },
      {
        "name": "POSTCODEAPIKEY",
        "valueFrom": "${postcodeApiKey}"
      },
      {
        "name": "ccms_soa_soapHeaderUserName",
        "valueFrom": "${ccms_soa_soapHeaderUserName}"
      },
      {
        "name": "ccms_soa_soapHeaderUserPassword",
        "valueFrom": "${ccms_soa_soapHeaderUserPassword}"
      },
      {
        "name": "USER_MANAGEMENT_API_ACCESS_TOKEN",
        "valueFrom": "${user_management_api_access_token}"
      },
      {
        "name": "SPRING_DATASOURCE_USERNAME",
        "valueFrom": "${spring_datasource_username}"
      },
      {
        "name": "SPRING_DATASOURCE_URL",
        "valueFrom": "${spring_datasource_url}"
      },
      {
        "name": "USER_MANAGEMENT_API_HOSTNAME",
        "valueFrom": "${user_management_api_hostname}"
      },
      {
        "name": "IDPMETADATAURL",
        "valueFrom": "${idpMetadataUrl}"
      },
      {
        "name": "IDPENTITYID",
        "valueFrom": "${idpIdentityID}"
      },
      {
        "name": "SPENTITYID",
        "valueFrom": "${SpEntityId}"
      },
      {
        "name": "SPENTITYURL",
        "valueFrom": "${SpEntityUrl}"
      },
      {
        "name": "LOGINURL",
        "valueFrom": "${loginUrl}"
      },
      {
        "name": "POSTCODEAPIURL",
        "valueFrom": "${postcodeApiUrl}"
      },
      {
        "name": "OPA_SECURITY_PASSWORD",
        "valueFrom": "${opa_security_password}"
      }
    ]
  }
]
