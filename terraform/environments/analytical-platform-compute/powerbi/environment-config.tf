################################################################################
# PowerBI Gateway - Environment Configuration
################################################################################

locals {
  environment_configurations = {
    development = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/GZpeWlEowP4P8/+uV27S/zXmFx7ZjrmsRcwa3Q8Kcb7uGACtJU3vvPjOCWW+RSmkaZmwQt4wjssMeXI2iVfSTqhOqoM8J657KhwxKnABfF+h0I9cDyvC1JISiWNVfPue9tCitmRyNtPB1Jq9aX9W0kiYWr35uLs05pzZBP2+IQJmtIWaWfQkca/7tgKIN3T52koWqj0vQdY9Tk9rDtrRuWao9fqrjJCe0f75/FAPBrrtgoJ7WjJRu4BOiBQzkkGHAWoRnlwDQzAHUEMDuOnTJjbu0AaBg3VoKhcBpehA9AAp+6rwmyphyrCrt9hTzyxw6As4F0Q+UQH1P6S4jt3GVh0LvOzLmIZeKf8AnbtkeoO3KK4xVfA8GwyuFTRKaR27Ipp3R2sfDe1US7OX6ha0Ftd70eWv1Fug8A+T/VviBJmFeXY/rE2yTl4gSkUkDggLBfSL7poZKZ18BDEC6RxRZBkPnxLbt5Cl9bmkORfkpducVz3MAF/L3oPYT2hQ1jnajFrKvuOsM2vJ9nFpxNlLoXI462Wr0JbsimuAKWLQoiyOoZLXX3fKqZ8n3KU8yFfbPKnHp66kLiitN46Gtine3sXWrVCwOjLftbZxeyd7SlRFDwVjSfcMole9RPjFDCbwZ0Zow18joqMeXaZo3gxH1ibPj7EAfjGrlwd64v5NVw== powerbi-gateway-aws-keypair-dev"
        tags = {
          environment_type = "development"
          criticality      = "low"
          project          = "powerbi-gateway"
        }
      }
    }

    test = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/GZpeWlEowP4P8/+uV27S/zXmFx7ZjrmsRcwa3Q8Kcb7uGACtJU3vvPjOCWW+RSmkaZmwQt4wjssMeXI2iVfSTqhOqoM8J657KhwxKnABfF+h0I9cDyvC1JISiWNVfPue9tCitmRyNtPB1Jq9aX9W0kiYWr35uLs05pzZBP2+IQJmtIWaWfQkca/7tgKIN3T52koWqj0vQdY9Tk9rDtrRuWao9fqrjJCe0f75/FAPBrrtgoJ7WjJRu4BOiBQzkkGHAWoRnlwDQzAHUEMDuOnTJjbu0AaBg3VoKhcBpehA9AAp+6rwmyphyrCrt9hTzyxw6As4F0Q+UQH1P6S4jt3GVh0LvOzLmIZeKf8AnbtkeoO3KK4xVfA8GwyuFTRKaR27Ipp3R2sfDe1US7OX6ha0Ftd70eWv1Fug8A+T/VviBJmFeXY/rE2yTl4gSkUkDggLBfSL7poZKZ18BDEC6RxRZBkPnxLbt5Cl9bmkORfkpducVz3MAF/L3oPYT2hQ1jnajFrKvuOsM2vJ9nFpxNlLoXI462Wr0JbsimuAKWLQoiyOoZLXX3fKqZ8n3KU8yFfbPKnHp66kLiitN46Gtine3sXWrVCwOjLftbZxeyd7SlRFDwVjSfcMole9RPjFDCbwZ0Zow18joqMeXaZo3gxH1ibPj7EAfjGrlwd64v5NVw== powerbi-gateway-aws-keypair-test"
        tags = {
          environment_type = "test"
          criticality      = "medium"
          project          = "powerbi-gateway"
        }
      }
    }

    production = {
      powerbi_gateway = {
        instance_type        = "t3a.xlarge"
        root_volume_size     = 100
        data_volume_size     = 300
        enable_monitoring    = true
        ami_maintenance_date = "2025-07-25T00:00:00Z"
        ssh_pub_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/GZpeWlEowP4P8/+uV27S/zXmFx7ZjrmsRcwa3Q8Kcb7uGACtJU3vvPjOCWW+RSmkaZmwQt4wjssMeXI2iVfSTqhOqoM8J657KhwxKnABfF+h0I9cDyvC1JISiWNVfPue9tCitmRyNtPB1Jq9aX9W0kiYWr35uLs05pzZBP2+IQJmtIWaWfQkca/7tgKIN3T52koWqj0vQdY9Tk9rDtrRuWao9fqrjJCe0f75/FAPBrrtgoJ7WjJRu4BOiBQzkkGHAWoRnlwDQzAHUEMDuOnTJjbu0AaBg3VoKhcBpehA9AAp+6rwmyphyrCrt9hTzyxw6As4F0Q+UQH1P6S4jt3GVh0LvOzLmIZeKf8AnbtkeoO3KK4xVfA8GwyuFTRKaR27Ipp3R2sfDe1US7OX6ha0Ftd70eWv1Fug8A+T/VviBJmFeXY/rE2yTl4gSkUkDggLBfSL7poZKZ18BDEC6RxRZBkPnxLbt5Cl9bmkORfkpducVz3MAF/L3oPYT2hQ1jnajFrKvuOsM2vJ9nFpxNlLoXI462Wr0JbsimuAKWLQoiyOoZLXX3fKqZ8n3KU8yFfbPKnHp66kLiitN46Gtine3sXWrVCwOjLftbZxeyd7SlRFDwVjSfcMole9RPjFDCbwZ0Zow18joqMeXaZo3gxH1ibPj7EAfjGrlwd64v5NVw== powerbi-gateway-aws-keypair-prod"
        tags = {
          environment_type = "production"
          criticality      = "high"
          project          = "powerbi-gateway"
        }
      }
    }
  }
}
