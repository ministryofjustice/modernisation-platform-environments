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

resource "aws_ssm_parameter" "ndelius-interface-ssm-param" {
  for_each  = local.ndelius_interface_params.parameter
  name      = each.value.name
  type      = each.value.type
  value     = each.value.value
  overwrite = each.value.overwrite

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}