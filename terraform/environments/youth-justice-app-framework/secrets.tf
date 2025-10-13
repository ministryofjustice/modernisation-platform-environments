#### This file can be used to store secrets specific to the member account ####
#### Secrets can be manually edited once created here ####

# temporary secret for snapshot identifier #todo remove after migration
resource "aws_secretsmanager_secret" "snapshot_identifier" {
  #checkov:skip=CKV2_AWS_57:temporary secret, no rotation needed
  name        = "yjaf-snapshot-identifier"
  description = "Snapshot identifier for Aurora RDS"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "snapshot_identifier" {
  #checkov:skip=CKV2_AWS_57:temporary secret, no rotation needed
  secret_id     = aws_secretsmanager_secret.snapshot_identifier.id
  secret_string = "dummy"
  lifecycle {
    ignore_changes = [secret_string]
  }
}

#Auto-admit create secret but later manually change value
resource "aws_secretsmanager_secret" "auto_admit_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "yjaf-auto-admit"
  description = "Password for autoadmin user"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "auto_admit_version" {
  secret_id = aws_secretsmanager_secret.auto_admit_secret.id
  secret_string = jsonencode(
    { "password" = "changeme"
      "username" = "connectivity.postman"
    "user" = "connectivity.postman@i2n.com" }
  )
  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "aws_secretsmanager_secret" "LDAP_administration_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "LDAP-administration-user"
  description = "Password for LDAP-administration"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

#checkov:skip=CKV_SECRET_6: Ignore this
resource "aws_secretsmanager_secret_version" "LDAP_administration_version" {
  #checkov:skip=CKV_SECRET_6: Ignore this
  secret_id = aws_secretsmanager_secret.LDAP_administration_secret.id
  #checkov:skip=CKV_SECRET_6: Ignore this
  secret_string = jsonencode(
    #checkov:skip=CKV_SECRET_6: Ignore this
    { "user_password_attribute" = "unicodePwd"
      "userdn"                  = "CN=admin2,OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com"
      #checkov:skip=CKV_SECRET_6: Ignore this
    "password" = "changeme" } #checkov:skip=CKV_SECRET_6: Ignore this
  )
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "LDAP_DC_secret" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "LDAP-DC-Connection-String"
  description = "DC connection string for LDAP"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "Auth_Email_Account" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_Auth_Email_Account"
  description = "YJAF Preprod limited user account credentials. Account is used by Auth Service to call Conversion service to send non-YJAF users their temporary passcode."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "Auth_Email_Account" {
  secret_id = aws_secretsmanager_secret.Auth_Email_Account.id
  secret_string = jsonencode(
    { "username" = "auth.service@i2n.com"
    "password" = "changeme" }
  )
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "Unit_test" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_Unit_test"
  description = "Used within Conversion configuration"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "Unit_test" {
  secret_id     = aws_secretsmanager_secret.Unit_test.id
  secret_string = "dummy" # InvalidRequestException: You must provide either SecretString or SecretBinary.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "google_api" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_google_api"
  description = "Used within UI for google maps"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "google_api" {
  secret_id     = aws_secretsmanager_secret.google_api.id
  secret_string = "dummy" # InvalidRequestException: You must provide either SecretString or SecretBinary.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "ordnance_survey_api" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_ordnance_survey_api"
  description = "Key used (by YP service) to return lat/long from postcode from Ordnance Survey Web API."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "ordnance_survey_api" {
  secret_id     = aws_secretsmanager_secret.ordnance_survey_api.id
  secret_string = "dummy" # InvalidRequestException: You must provide either SecretString or SecretBinary.
  lifecycle {
    ignore_changes = [secret_string]
  }
}


### Tableau Secrets ###
## Secret to hold Tableau administration details
resource "aws_secretsmanager_secret" "ad_credentials" {
  # checkov:skip=CKV2_AWS_57: "Rotation needs to be coprdinated with changes to Tableau configuration."

  name        = "${local.environment}/Tableau/Administration"
  description = "Tableau Administration, site, group, user and password."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

# The password will be polulatd durring tableau instalation
resource "aws_secretsmanager_secret_version" "ad_credentials" {
  # checkov:skip=CKV2_AWS_57: "Rotation needs to be coordinated with changes to Tableau configuration."

  secret_id = aws_secretsmanager_secret.ad_credentials.id
  secret_string = jsonencode(
    { "Tableau Admin Group" = "tsmadmin"
      "Admin Username"      = "tabadmin"
    "Password" = "changeme" }
  )

  lifecycle {
    ignore_changes = [secret_string]
  }
}

## Secret to hold the tableau domain user and its passoword
resource "aws_secretsmanager_secret" "tableau_admin" {
  # checkov:skip=CKV2_AWS_57: "Rotation needs to be coordinated with changes to Tableau configuration."

  name        = "tableau_ad_read_credentials"
  description = "The tableau user that is used to read ad users and groups. It also acts as the initial Tableau System Administrator on install."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

# The password will be polulated after the user is imported to AD and before Tableau instalation.
resource "aws_secretsmanager_secret_version" "tableau_admin" {
  secret_id = aws_secretsmanager_secret.tableau_admin.id
  secret_string = jsonencode(
    { tableau_ad_read_account = "tableau"
    tableau-ad_read_password = "changeme" }
  )

  lifecycle {
    ignore_changes = [secret_string]
  }
}

## Secret to hold the credentials used by YJAF to access tableau
resource "aws_secretsmanager_secret" "yjaf_credentials" {
  # checkov:skip=CKV2_AWS_57: "Rotation needs to be coordinated with changes to Tableau configuration."

  name        = "${local.environment}/Tableau/app/yjb"
  description = "Tableau secrets for embedding report into YJAF. Used by Auth service."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

# The values will be populated after installing Tableau. And may need to be refreshed following cutover.
resource "aws_secretsmanager_secret_version" "yjaf_credentials" {
  secret_id = aws_secretsmanager_secret.yjaf_credentials.id
  secret_string = jsonencode(
    { ClientID = "changeme"
      SecretID = "changeme"
    Value = "changeme" }
  )

  lifecycle {
    ignore_changes = [secret_string]
  }
}
