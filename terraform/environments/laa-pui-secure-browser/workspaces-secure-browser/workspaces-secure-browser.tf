### SECURITY GROUP

module "workspacesweb_security_group" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = local.vpc_id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp"]
}

### NETWORK SETTINGS

resource "aws_workspacesweb_network_settings" "main" {
  count = local.create_resources ? 1 : 0

  vpc_id             = local.vpc_id
  subnet_ids         = local.subnet_ids
  security_group_ids = [module.workspacesweb_security_group[0].security_group_id]
}

### WORKSPACES WEB PORTALS
moved {
  from = aws_workspacesweb_portal.main
  to   = aws_workspacesweb_portal.external["external_1"]
}

resource "aws_workspacesweb_portal" "external" {
  for_each = local.create_resources ? local.portals : {}

  display_name = each.value
}

### USER SETTINGS

# Standard user settings for external_2 (no SSO)
resource "aws_workspacesweb_user_settings" "main" {
  count = local.create_resources ? 1 : 0

  # Required settings
  copy_allowed     = "Enabled"
  download_allowed = "Enabled"
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

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-user-settings-main"
    }
  )
}

# User settings with SSO extension (cookie sync) for external_1
resource "aws_workspacesweb_user_settings" "sso" {
  count = local.create_resources ? 1 : 0

  # Required settings - same as main
  copy_allowed     = "Enabled"
  download_allowed = "Enabled"
  paste_allowed    = "Enabled"
  print_allowed    = "Disabled"
  upload_allowed   = "Enabled"

  # Optional settings - same as main
  deep_link_allowed                  = "Enabled"
  disconnect_timeout_in_minutes      = 60
  idle_disconnect_timeout_in_minutes = 15

  # Enable SSO extension and define which cookies to sync -- DISABLED PENDING SEC REVIEW
  # cookie_synchronization_configuration {
  #   # Microsoft Entra ID
  #   allowlist {
  #     domain = "microsoftonline.com"
  #   }

  #   # Microsoft authentication domains
  #   allowlist {
  #     domain = "microsoft.com"
  #   }

  #   allowlist {
  #     domain = "msftidentity.com"
  #   }

  #   allowlist {
  #     domain = "msidentity.com"
  #   }

  #   # LAA sign-in domain
  #   allowlist {
  #     domain = local.laa_sign_in_url
  #   }

  #   # LAA legal aid services domain
  #   allowlist {
  #     domain = local.legal_aid_services_url
  #   }
  # }

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

  tags = merge(
    local.tags,
    {
      Name = "workspacesweb-user-settings-sso"
    }
  )
}

### BROWSER SETTINGS

resource "aws_workspacesweb_browser_settings" "main" {
  count = local.create_resources ? 1 : 0

  browser_policy = jsonencode({
    "chromePolicies" = {
      "ManagedBookmarks" = {
        "value" = [
          {
            "name" = "PUI"
            "url"  = "https://${local.pui_url}/civil"
          },
          {
            "name" = "OIA Hub"
            "url"  = "https://${local.oia_url}"
          }
        ]
      }
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
          local.pui_url,
          local.oia_url,
          local.laa_sign_in_url,
          local.legal_aid_services_url,
          "mysignins.microsoft.com",
          "go.microsoft.com",
          "portal.manage.microsoft.com",
          "login.live.com",
          "google-exention-bucket.s3.eu-west-2.amazonaws.com",
          "chrome://print/",
          "chrome-untrusted://print/",
          "chrome://new-tab-page",
          "legalaidlearning.justice.gov.uk",
          "assets.publishing.service.gov.uk",
          "www.gov.uk",
          "www.justice.gov.uk",
          "justice.gov.uk",
          "legalservices.gov.uk",
          "lsconline.legalservices.gov.uk"
        ]
      }
      "AlwaysOpenPdfExternally" = {
        "value" = false
      }
      "DisablePrintPreview" = {
        "value" = false
      }
      "DownloadRestrictions" = {
        "value" = 0
      }
      "ExtensionSettings" = {
        "value" = {
          "mhjfbmdgcfjbbpaeojofohoefgiehjai" = {
            "installation_mode" = "allowed"
          }
          "pgmgimgbioofngenfkfkldhkfcnaepgn" = {
            "installation_mode" = "force_installed"
            "update_url"        = "https://google-exention-bucket.s3.eu-west-2.amazonaws.com/update.xml"
          }
        }
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
        "value" = true
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
  count = local.create_resources ? 1 : 0

  display_name         = "laa-workspaces-web-session-logger"
  customer_managed_key = aws_kms_key.workspacesweb_session_logs[0].arn

  additional_encryption_context = {
    Environment = local.environment
    Application = "laa-pui-secure-browser"
  }

  event_filter {
    all {}
  }

  log_configuration {
    s3 {
      bucket           = module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_id
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
  for_each = local.create_resources ? local.portals : {}

  portal_arn           = aws_workspacesweb_portal.external[each.key].portal_arn
  network_settings_arn = aws_workspacesweb_network_settings.main[0].network_settings_arn
}

### USER SETTINGS ASSOCIATIONS

moved {
  from = aws_workspacesweb_user_settings_association.main
  to   = aws_workspacesweb_user_settings_association.external_1
}

# External_1 uses SSO user settings with cookie synchronization
resource "aws_workspacesweb_user_settings_association" "external_1" {
  count = local.create_resources ? 1 : 0

  portal_arn        = aws_workspacesweb_portal.external["external_1"].portal_arn
  user_settings_arn = aws_workspacesweb_user_settings.sso[0].user_settings_arn
}

# External_2 uses standard user settings without SSO
resource "aws_workspacesweb_user_settings_association" "external_2" {
  count = local.create_resources ? 1 : 0

  portal_arn        = aws_workspacesweb_portal.external["external_2"].portal_arn
  user_settings_arn = aws_workspacesweb_user_settings.main[0].user_settings_arn
}

### BROWSER SETTINGS ASSOCIATIONS

moved {
  from = aws_workspacesweb_browser_settings_association.main
  to   = aws_workspacesweb_browser_settings_association.external["external_1"]
}

resource "aws_workspacesweb_browser_settings_association" "external" {
  for_each = local.create_resources ? local.portals : {}

  portal_arn           = aws_workspacesweb_portal.external[each.key].portal_arn
  browser_settings_arn = aws_workspacesweb_browser_settings.main[0].browser_settings_arn
}

### SESSION LOGGER ASSOCIATIONS

moved {
  from = aws_workspacesweb_session_logger_association.main
  to   = aws_workspacesweb_session_logger_association.external["external_1"]
}

resource "aws_workspacesweb_session_logger_association" "external" {
  for_each = local.create_resources ? local.portals : {}

  portal_arn         = aws_workspacesweb_portal.external[each.key].portal_arn
  session_logger_arn = aws_workspacesweb_session_logger.main[0].session_logger_arn
}
