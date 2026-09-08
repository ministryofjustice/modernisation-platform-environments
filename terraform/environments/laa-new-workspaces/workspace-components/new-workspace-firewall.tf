# =============================================================================
# AWS Network Firewall - WorkSpaces FQDN Allowlist Rule Groups
# =============================================================================
# Migrated from Aviatrix egress-filter.yml

# IMPORTANT - these rule groups must be referenced in an
# aws_networkfirewall_firewall_policy to take effect. This file only defines
# the rulebases as requested.
# =============================================================================

# -----------------------------------------------------------------------------
# Rule Group 1 — AWS Service Endpoints
# Covers: WorkSpaces Application Manager (WAM), S3, SQS, CloudFront
#
# NOTE: Consider replacing S3 and SQS with VPC Gateway/Interface Endpoints to
# keep that traffic off the internet entirely — you could then remove those
# entries from this list and reduce the attack surface.
# -----------------------------------------------------------------------------
# resource "aws_networkfirewall_rule_group" "workspaces_aws_endpoints" {
#   name     = "workspaces-aws-endpoints"
#   capacity = 15
#   type     = "STATEFUL"

#   rule_group {
#     rules_source {
#       rules_source_list {
#         generated_rules_type = "ALLOWLIST"
#         target_types         = ["TLS_SNI", "HTTP_HOST"]
#         targets = [
#           # "wam-idb.eu-west-2.amazonaws.com",
#           # "wam-ps.eu-west-2.amazonaws.com",
#           # ".s3.amazonaws.com", # covers s3.amazonaws.com and ".s3.amazonaws.com
#           # ".s3-external-1.amazonaws.com",
#           # ".s3-eu-west-2.amazonaws.com",
#           # "sqs.eu-west-2.amazonaws.com",
#           # "cloudfront.amazonaws.com",
#         ]
#       }
#     }
#   }

#   tags = {
#     Name = "workspaces-aws-endpoints"
#   }
# }

# -----------------------------------------------------------------------------
# Rule Group 2 — Microsoft Services
# Taken from https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "workspaces_microsoft_services" {
  name     = "workspaces-microsoft-services"
  capacity = 1000
  type     = "STATEFUL"

  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets = [
          # Windows Update & Defender
          ".windowsupdate.com", # covers ".windowsupdate.com and ".download.windowsupdate.com
          "wustat.windows.com",
          "client.wns.windows.com",
          "skydrive.wns.windows.com",
          "adldefinitionupdates-wu.azurewebsites.net",

          ".cloud.microsoft",
          ".static.microsoft",
          ".usercontent.microsoft",
          ".sharepoint.com",
          # "storage.live.com",
          ".wns.windows.com",
          "admin.onedrive.com",
          "officeclient.microsoft.com",
          "g.live.com",
          "oneclient.sfx.ms",
          ".sharepointonline.com",
          "spoprod-a.akamaihd.net",
          ".svc.ms",
          ".officeapps.live.com",
          ".online.office.com",
          "office.live.com",
          ".office.net",
          ".onenote.com",
          # "cdn.onenote.net",
          "ajax.aspnetcdn.com",
          "apis.live.net",
          "www.onedrive.com",
          ".auth.microsoft.com",
          ".msftidentity.com",
          ".msidentity.com",
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
          "graph.microsoft.com",
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
          ".hip.live.com",
          ".microsoftonline-p.com",
          ".microsoftonline.com",
          ".msauth.net",
          ".msauthimages.net",
          ".msecnd.net",
          ".msftauth.net",
          ".msftauthimages.net",
          ".phonefactor.net",
          "enterpriseregistration.windows.net",
          ".protection.office.com",
          ".security.microsoft.com",
          "compliance.microsoft.com",
          "defender.microsoft.com",
          "purview.microsoft.com",
          ".portal.cloudappsecurity.com",
          ".aria.microsoft.com",
          ".events.data.microsoft.com",
          ".o365weve.com",
          "amp.azure.net",
          "appsforoffice.microsoft.com",
          "assets.onestore.ms",
          "auth.gfx.ms",
          "c1.microsoft.com",
          "dgps.support.microsoft.com",
          "docs.microsoft.com",
          "msdn.microsoft.com",
          "platform.linkedin.com",
          "prod.msocdn.com",
          "shellprod.msocdn.com",
          "support.microsoft.com",
          "technet.microsoft.com",
          ".office365.com",
          ".aadrm.com",
          ".azurerms.com",
          ".informationprotection.azure.com",
          "ecn.dev.virtualearth.net",
          "informationprotection.hosting.portal.azure.net",
          "o15.officeredir.microsoft.com",
          "officepreviewredir.microsoft.com",
          "officeredir.microsoft.com",
          "r.office.microsoft.com",
          "activation.sls.microsoft.com",
          "crl.microsoft.com",
          "office15client.microsoft.com",
          "go.microsoft.com",
          "cdn.odc.officeapps.live.com",
          "officecdn.microsoft.com",
          "otelrules.azureedge.net",
          ".entrust.net",
          ".geotrust.com",
          ".omniroot.com",
          ".public-trust.com",
          ".symcb.com",
          ".symcd.com",
          ".verisign.com",
          ".verisign.net",
          "cacerts.digicert.com",
          "cert.int-x3.letsencrypt.org",
          "crl.globalsign.com",
          "crl.globalsign.net",
          "crl.identrust.com",
          "crl3.digicert.com",
          "crl4.digicert.com",
          "isrg.trustid.ocsp.identrust.com",
          "mscrl.microsoft.com",
          "ocsp.digicert.com",
          "ocsp.globalsign.com",
          "ocsp.msocsp.com",
          "ocsp2.globalsign.com",
          "ocspx.digicert.com",
          "oneocsp.microsoft.com",
          "secure.globalsign.com",
          "www.digicert.com",
          "www.microsoft.com",
          ".office.com",
          "www.microsoft365.com",
          ".azure-apim.net",
          ".flow.microsoft.com",
          ".powerapps.com",
          ".powerautomate.com",
          ".activity.windows.com",
          # ".cortana.ai",
          "admin.microsoft.com",
          "cdn.uci.officeapps.live.com",
          "account.live.com",
          "login.live.com"

        ]
      }
    }
  }

  tags = {
    Name = "workspaces-microsoft-services"
  }
}

# -----------------------------------------------------------------------------
# Rule Group 3 — OneDrive, Live Services & Miscellaneous
# Covers: OneDrive, live.com consumer services, SkyDrive, sfx.ms delivery,
#         MOJ-specific endpoints, third-party apps bundled with Office/WorkSpaces
#
# Review candidates (flagged with # REVIEW):
#   - StaffHub entries: Microsoft retired StaffHub in Jan 2020; may no longer be needed
#   - Analytics SDKs (helpshift, localytics, branch.io, adjust, crashlytics, fabric.io,
#     vas.samsungapps): These are mobile SDK endpoints included in the original Office
#     365 allowlist but are unlikely to be relevant for desktop WorkSpaces.
#     Consider removing after testing.
#   - connect.facebook.net: Used by some Office add-ins; review if appropriate
#     for your security posture.
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "workspaces_onedrive_live_misc" {
  name     = "workspaces-onedrive-live"
  capacity = 70
  type     = "STATEFUL"

  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets = [

          # MOJ specific
          "sts.justice.gov.uk",
          "justiceuk-my.sharepoint.com"

        ]
      }
    }
  }

  tags = {
    Name = "workspaces-onedrive-live"
  }
}

# -----------------------------------------------------------------------------
# Rule Group 4 — Certificate Authorities (PKI / CRL / OCSP)
# Covers: DigiCert, GlobalSign, Entrust, Verisign/Symantec, Let's Encrypt,
#         IdenTrust, Sectigo, UserTrust, Omniroot, GeoTrust, Public Trust
#
# NOTE: CRL and OCSP traffic typically runs over HTTP (port 80), not HTTPS.
# Ensure your firewall policy stateful rule group is configured to inspect
# HTTP as well as HTTPS for these to be matched by HTTP_HOST.
#
# Key consolidations vs original list:
#   ".digicert.com"    — replaces cacerts/crl3/crl4/ocsp/ocspx/www.digicert.com
#   ".globalsign.com"  — replaces crl/ocsp/ocsp2/secure.globalsign.com
#   ".identrust.com"   — replaces apps/crl/isrg.trustid.ocsp.identrust.com
#   ".verisign.com"    — replaces all evintl-"/evsecure-" entries
#   ".usertrust.com"   — replaces crl/ocsp/crt.usertrust.com
#   ".omniroot.com"    — replaces cacert/cacert.a/ocsp/vassg142." entries
#   ".letsencrypt.org" — replaces cert.int-x3 and ocsp.int-x3 entries
# -----------------------------------------------------------------------------
# resource "aws_networkfirewall_rule_group" "workspaces_certificate_authorities" {
#   name     = "workspaces-certificate-authorities"
#   capacity = 25
#   type     = "STATEFUL"

#   rule_group {
#     rules_source {
#       rules_source_list {
#         generated_rules_type = "ALLOWLIST"
#         target_types         = ["TLS_SNI", "HTTP_HOST"]
#         targets = [
#           # ".digicert.com",
#           # ".globalsign.com",
#           # ".globalsign.net",
#           # ".entrust.net",
#           # ".geotrust.com",
#           # ".verisign.com",
#           # ".verisign.net",
#           # ".symcb.com",
#           # ".symcd.com",
#           # ".omniroot.com",
#           # ".public-trust.com",
#           # ".identrust.com",
#           # ".letsencrypt.org",
#           # ".usertrust.com",
#           # "ocsp.msocsp.com", # Microsoft OCSP responder — not under .microsoft.com TLD
#           # "crl.sectigo.com",
#           # "ocsp.sectigo.com",
#         ]
#       }
#     }
#   }
# 
#   tags = {
#     Name = "workspaces-certificate-authorities"
#   }
# }


# -----------------------------------------------------------------------------
# Rule Group 5 — LAA Applications
# Covers: Any public (non-TGW) traffic to other LAA applications
# -----------------------------------------------------------------------------
# resource "aws_networkfirewall_rule_group" "workspaces_laa_apps" {
#   name     = "workspaces-laa-apps"
#   capacity = 200
#   type     = "STATEFUL"

#   rule_group {
#     stateful_rule_options {
#       rule_order = "STRICT_ORDER"
#     }
#     rules_source {
#       rules_source_list {
#         generated_rules_type = "ALLOWLIST"
#         target_types         = ["TLS_SNI", "HTTP_HOST"]
#         targets = [
#           ".laa-development.modernisation-platform.service.justice.gov.uk"
#         ]
#       }
#     }
#   }

#   tags = {
#     Name = "workspaces-laa-apps"
#   }
# }



# -----------------------------------------------------------------------------
# WorkSpaces Network Firewall policy and firewall
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "workspaces_web_allowlist" {
  name        = "workspaces-web-allowlist-policy"
  description = "Allow only approved WorkSpaces FQDN traffic and drop all other stateful traffic."

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_default_actions           = ["aws:alert_strict"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.workspaces_microsoft_services.arn
      priority     = 1
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.workspaces_onedrive_live_misc.arn
      priority     = 2
    }

    # stateful_rule_group_reference {
    #   resource_arn = aws_networkfirewall_rule_group.workspaces_laa_apps.arn
    #   priority     = 3
    # }


  }

  tags = {
    Name = "workspaces-web-allowlist-policy"
  }
}

resource "aws_networkfirewall_firewall" "workspaces_web_allowlist" {
  name                = "workspaces-web-allowlist-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.workspaces_web_allowlist.arn
  vpc_id              = aws_vpc.workspaces.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall_a.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.firewall_b.id
  }

  tags = {
    Name = "workspaces-web-allowlist-firewall"
  }
}

# CloudWatch Log Groups for firewall
resource "aws_cloudwatch_log_group" "firewall_flow_logs" {
  name              = "/aws/network-firewall/workspaces/flow-logs"
  retention_in_days = 7

  tags = {
    Name = "workspaces-firewall-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "firewall_alert_logs" {
  name              = "/aws/network-firewall/workspaces/alert-logs"
  retention_in_days = 7

  tags = {
    Name = "workspaces-firewall-alert-logs"
  }
}

# Enable firewall logging
resource "aws_networkfirewall_logging_configuration" "workspaces" {
  firewall_arn = aws_networkfirewall_firewall.workspaces_web_allowlist.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert_logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_flow_logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }


  }
}