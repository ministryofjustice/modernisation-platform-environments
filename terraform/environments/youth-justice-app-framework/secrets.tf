#### This file can be used to store secrets specific to the member account ####
#### Secrets can be manually edited once created here ####

#Auto-admit create secret but later manually change value
resource "aws_secretsmanager_secret" "auto_admit_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "yjaf-auto-admit"
  description = "Password for autoadmin user"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "aurora_rotated_user_version" {
  secret_id = aws_secretsmanager_secret.auto_admit_secret.id
  secret_string = jsonencode({
    username = "connectivity.postman"
    user     = "connectivity.postman@i2n.com"
  })
}


resource "aws_secretsmanager_secret" "auto_admit_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "LDAP-administration"
  description = "Password for LDAP-administration"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "aurora_rotated_user_version" {
  secret_id = aws_secretsmanager_secret.auto_admit_secret.id
  secret_string = jsonencode({
    userdn                  = "CN=admin2,OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com"
    user_password_attribute = "unicodePwd"
  })
}


