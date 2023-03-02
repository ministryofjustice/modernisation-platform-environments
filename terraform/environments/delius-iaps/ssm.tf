# Dev placeholder values hardcoded for testing. Values in pre and prod to be set manually on initial deployment
resource "aws_ssm_parameter" "im-interface-oracle-user" {
  name      = "/IMInterface/IAPSOracle/user"
  type      = "String"
  value     = "dev-placeholder-iapsoracle-user"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-oracle-password" {
  name      = "/IMInterface/IAPSOracle/password"
  type      = "SecureString"
  value     = "dev-placeholder-iapsoracle-password"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-soap-odbc-dsn" {
  name      = "/IMInterface/SOAPServer/ODBC/dsn"
  type      = "String"
  value     = "dev-placeholder-soapserver-odbc-dsn"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-soap-odbc-server" {
  name      = "/IMInterface/SOAPServer/ODBC/server"
  type      = "String"
  value     = "dev-placeholder-soapserver-odbc-server"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-soap-odbc-database" {
  name      = "/IMInterface/SOAPServer/ODBC/database"
  type      = "String"
  value     = "dev-placeholder-soapserver-odbc-database"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-soap-odbc-uid" {
  name      = "/IMInterface/SOAPServer/ODBC/uid"
  type      = "String"
  value     = "dev-placeholder-soapserver-odbc-uid"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "im-interface-soap-odbc-pwd" {
  name      = "/IMInterface/SOAPServer/ODBC/pwd"
  type      = "SecureString"
  value     = "dev-placeholder-soapserver-odbc-pwd"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-user" {
  name      = "/NDeliusInterface/Interface/user"
  type      = "String"
  value     = "dev-placeholder-ndelius-interface-user"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-password" {
  name      = "/NDeliusInterface/Interface/password"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-password"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-replicapasswordcoded" {
  name      = "/NDeliusInterface/Interface/replicapwdcoded"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-replicapasswordcoded"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-soappasscoded" {
  name      = "/NDeliusInterface/Interface/soappwdcoded"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-soappasscoded"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-pwdcoded" {
  name      = "/NDeliusInterface/Interface/pwdcoded"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-passwordcoded"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-odbc-dsn" {
  name      = "/NDeliusInterface/Interface/ODBC/dsn"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-odbc-dsn"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-odbc-uid" {
  name      = "/NDeliusInterface/Interface/ODBC/uid"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-odbc-uid"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-odbc-pwd" {
  name      = "/NDeliusInterface/Interface/ODBC/pwd"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-odbc-pwd"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-email-smtpuser" {
  name      = "/NDeliusInterface/Email/smtpuser"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-email-smtpuser"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-email-password" {
  name      = "/NDeliusInterface/Email/password"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-email-password"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ndelius-interface-email-passwordcoded" {
  name      = "/NDeliusInterface/Email/passwordcoded"
  type      = "SecureString"
  value     = "dev-placeholder-ndelius-interface-email-passwordcoded"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}