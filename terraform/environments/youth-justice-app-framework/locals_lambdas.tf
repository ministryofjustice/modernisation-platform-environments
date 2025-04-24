locals {
  split-ds-managed-ad-ips             = tolist(module.ds.dns_ip_addresses)
  s3-cross-account-replication-s3-arn = "arn:aws:s3:::redshift-serverless-yjb-${local.environment}-reporting"
  update-dc-names = {
    function_zip_file = "lambda_code/update-dc-names.zip"
    function_name     = "update-dc-names"
    handler           = "update_dc_names.lambda_handler"
    iam_role_name     = "update-dc-names-lambda-role"
    environment_variables = {
      LOG_GROUP_NAME = module.ds.cloudwatch_log_group_name
      LOG_STREAMS    = "${local.split-ds-managed-ad-ips[0]}-SecurityEvents,${local.split-ds-managed-ad-ips[1]}-SecurityEvents"
      SECRET_NAME    = aws_secretsmanager_secret.LDAP_DC_secret.name
    }
  }

  s3-cross-account-replication = {
    function_zip_file  = "lambda_code/s3-cross-account-replication.zip"
    function_name      = "s3-cross-account-replication"
    handler            = "s3-cross-account-replication.lambda_handler"
    iam_role_name      = "s3-cross-account-replication-lambda-role"
    lambda_memory_size = 512
    lambda_timeout     = 900
  }

  serverlessrepo-lambda-canary = {
    function_zip_file = "lambda_code/serverlessrepo-lambda-canary.zip"
    function_name     = "serverlessrepo-lambda-canary"
    handler           = "serverlessrepo-lambda-canary.lambda_handler"
    iam_role_name     = "serverlessrepo-lambda-canary-lambda-role"
    environment_variables = {
      expected = "UP"
      site_1   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/auth/../../../actuator/health"        #auth
      site_11  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/placements/../../../actuator/health"  #placements
      site_12  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/refdata/../../../actuator/health"     #refdata
      site_13  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/returns/../../../actuator/health"     #returns
      site_14  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/sentences/../../../actuator/health"   #sentences
      site_15  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/transfers/../../../actuator/health"   #transfers
      site_17  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/views/../../../actuator/health"       #views
      site_18  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/workflow/../../../actuator/health"    #workflow
      site_19  = "http://private-lb.${local.environment}.yjaf:8080/api/v1/yp/../../../actuator/health"          #yp
      site_2   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/bands/../../../actuator/health"       #bands
      site_3   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/bu/../../../actuator/health"          #bu
      site_4   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/case/../../../actuator/health"        #case
      site_5   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/cmm/../../../actuator/health"         #cmm
      site_6   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/conversions/../../../actuator/health" #conversions
      site_8   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/dal/../../../actuator/health"         #dal
      site_9   = "http://private-lb.${local.environment}.yjaf:8080/api/v1/documents/../../../actuator/health"   #documents
    }
    vpc_config = {
      subnet_ids         = local.private_subnet_list[*].id
      security_group_ids = [module.serverlessrepo-lambda-canary-sg.security_group_id]
    }
  }


  update-dc-names-role = {
    name              = "update-dc-names-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/update-dc-names-role-policy.json"
    policy_template_vars = {
      ldap_urls_secret_arn = aws_secretsmanager_secret.LDAP_DC_secret.arn
      account_number       = local.environment_management.account_ids[terraform.workspace]
    }
  }

  s3-cross-account-replication-role = {
    name              = "s3-cross-account-replication-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/s3-cross-account-replication-role-policy.json"
    policy_template_vars = {
      account_number = local.environment_management.account_ids[terraform.workspace]
    }
  }

  serverlessrepo-lambda-canary-role = {
    name              = "serverlessrepo-lambda-canary-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/serverlessrepo-lambda-canary-role-policy.json"
    policy_template_vars = {
      account_number = local.environment_management.account_ids[terraform.workspace]
    }
  }
}
