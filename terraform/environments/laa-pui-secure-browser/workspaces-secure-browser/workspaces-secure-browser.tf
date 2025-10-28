### SECURITY GROUP

module "workspacesweb_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = data.aws_vpc.shared.id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp"]
}

### NETWORK SETTINGS

resource "aws_workspacesweb_network_settings" "main" {
  vpc_id             = data.aws_vpc.shared.id
  subnet_ids         = [data.aws_subnet.private_aza.id, data.aws_subnet.private_azc.id]
  security_group_ids = [module.workspacesweb_security_group.security_group_id]
}

### WORKSPACES WEB PORTALS
moved {
  from = aws_workspacesweb_portal.main
  to   = aws_workspacesweb_portal.external["external_1"]
}

resource "aws_workspacesweb_portal" "external" {
  for_each = local.portals

  display_name = each.value
}

### USER SETTINGS

# Create a user settings configuration
resource "aws_workspacesweb_user_settings" "main" {
  # Required settings
  copy_allowed     = "Enabled"
  download_allowed = "Disabled"
  paste_allowed    = "Enabled"
  print_allowed    = "Disabled"
  upload_allowed   = "Enabled"

  # Optional settings
  deep_link_allowed                  = "Enabled"
  disconnect_timeout_in_minutes      = 60
  idle_disconnect_timeout_in_minutes = 15

  toolbar_configuration {
    toolbar_type = "Docked"
    visual_mode  = "Dark"
    hidden_toolbar_items = [
      "Webcam",
      "Microphone",
      "FullScreen",
      "DualMonitor",
      "Windows"
    ]
  }
}

### BROWSER SETTINGS

resource "aws_workspacesweb_browser_settings" "main" {
  browser_policy = jsonencode({
    "chromePolicies" = {
      "BookmarkBarEnabled" = {
        "value" = true
      }
      "RestoreOnStartup" = {
        "value" = 5
      }
      "RestoreOnStartupURLs" = {
        "value" = []
      }
      "URLBlocklist" = {
        "value" = [
          "*",
          "view-source:*",
          "chrome://tasks",
          "chrome://task-manager",
          "chrome://discards",
          "chrome://performance",
          "chrome-devtools://*"
        ]
      }
      "URLAllowlist" = {
        "value" = [
          "[*.]auth.microsoft.com",
          "[*.]msftidentity.com",
          "[*.]msidentity.com",
          "account.activedirectory.windowsazure.com",
          "accounts.accesscontrol.windows.net",
          "adminwebservice.microsoftonline.com",
          "api.passwordreset.microsoftonline.com",
          "autologon.microsoftazuread-sso.com",
          "becws.microsoftonline.com",
          "ccs.login.microsoftonline.com",
          "clientconfig.microsoftonline-p.net",
          "companymanager.microsoftonline.com",
          "device.login.microsoftonline.com",
          "graph.windows.net",
          "login-us.microsoftonline.com",
          "login.microsoft.com",
          "login.microsoftonline-p.com",
          "login.microsoftonline.com",
          "login.windows.net",
          "logincert.microsoftonline.com",
          "loginex.microsoftonline.com",
          "nexus.microsoftonline-p.com",
          "passwordreset.microsoftonline.com",
          "provisioningapi.microsoftonline.com",
          "[*.]hip.live.com",
          "[*.]microsoftonline-p.com",
          "[*.]microsoftonline.com",
          "[*.]msauth.net",
          "[*.]msauthimages.net",
          "[*.]msecnd.net",
          "[*.]msftauth.net",
          "[*.]msftauthimages.net",
          "[*.]phonefactor.net",
          "enterpriseregistration.windows.net",
          "chrome://new-tab-page",
          "mysignins.microsoft.com",
          "go.microsoft.com",
          "portal.manage.microsoft.com",
          "laa-sign-in.external-identity.service.justice.gov.uk/"
        ]
      }
      "AllowDeletingBrowserHistory" = {
        "value" = false
      }
      "IncognitoModeAvailability" = {
        "value" = 1
      }
      "DeveloperToolsAvailability" = {
        "value" = 2
      }
      "TaskManagerEndProcessEnabled" = {
        "value" = false
      }
      "PasswordManagerEnabled" = {
        "value" = false
      }
      "PrintingEnabled" = {
        "value" = false
      }
      "SafeBrowsingProtectionLevel" = {
        "value" = 1
      }
    }
  })

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-browser-settings"
    }
  )
}

### SESSION LOGGER FOR SESSION LOGGING

resource "aws_workspacesweb_session_logger" "main" {
  display_name         = "laa-workspaces-web-session-logger"
  customer_managed_key = aws_kms_key.workspacesweb_session_logs.arn

  additional_encryption_context = {
    Environment = local.environment
    Application = "laa-pui-secure-browser"
  }

  event_filter {
    all {}
  }

  log_configuration {
    s3 {
      bucket           = module.s3_bucket_workspacesweb_session_logs.s3_bucket_id
      bucket_owner     = data.aws_caller_identity.current.account_id
      folder_structure = "NestedByDate"
      key_prefix       = "workspaces-web-logs/"
      log_file_format  = "JSONLines"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-session-logger"
    }
  )

}

### NETWORK SETTINGS ASSOCIATIONS

moved {
  from = aws_workspacesweb_network_settings_association.main
  to   = aws_workspacesweb_network_settings_association.external["external_1"]
}

resource "aws_workspacesweb_network_settings_association" "external" {
  for_each = local.portals

  portal_arn           = aws_workspacesweb_portal.external[each.key].portal_arn
  network_settings_arn = aws_workspacesweb_network_settings.main.network_settings_arn
}

### USER SETTINGS ASSOCIATIONS

moved {
  from = aws_workspacesweb_user_settings_association.main
  to   = aws_workspacesweb_user_settings_association.external["external_1"]
}

resource "aws_workspacesweb_user_settings_association" "external" {
  for_each = local.portals

  portal_arn        = aws_workspacesweb_portal.external[each.key].portal_arn
  user_settings_arn = aws_workspacesweb_user_settings.main.user_settings_arn
}

### BROWSER SETTINGS ASSOCIATIONS

moved {
  from = aws_workspacesweb_browser_settings_association.main
  to   = aws_workspacesweb_browser_settings_association.external["external_1"]
}

resource "aws_workspacesweb_browser_settings_association" "external" {
  for_each = local.portals

  portal_arn           = aws_workspacesweb_portal.external[each.key].portal_arn
  browser_settings_arn = aws_workspacesweb_browser_settings.main.browser_settings_arn
}

### SESSION LOGGER ASSOCIATIONS

moved {
  from = aws_workspacesweb_session_logger_association.main
  to   = aws_workspacesweb_session_logger_association.external["external_1"]
}

resource "aws_workspacesweb_session_logger_association" "external" {
  for_each = local.portals

  portal_arn         = aws_workspacesweb_portal.external[each.key].portal_arn
  session_logger_arn = aws_workspacesweb_session_logger.main.session_logger_arn
}
