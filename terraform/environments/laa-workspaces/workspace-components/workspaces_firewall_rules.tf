# =============================================================================
# AWS Network Firewall - WorkSpaces FQDN Allowlist Rule Groups
# =============================================================================
# Migrated from Aviatrix egress-filter.yml
#
# Conversion notes:
#   - Aviatrix "*.domain.com" → Network Firewall ".domain.com"
#     (the leading dot matches the apex domain AND all subdomains at any depth)
#   - Duplicates removed; entries subsumed by broader wildcards are not repeated
#     e.g. individual *.microsoft.com subdomains removed as ".microsoft.com" covers them
#   - Multi-level wildcards (*.*.domain.com) removed; covered by parent .domain.com entry
#   - {{ region }} Jinja2 variables replaced with var.aws_region Terraform input
#   - Four logical rule groups to keep each well under the e0-domain limit
#
# IMPORTANT - these rule groups must be referenced in an
# aws_networkfirewall_firewall_policy to take effect. This file only defines
# the rulebases as requested.
# =============================================================================

variable "aws_region" {
  description = "AWS region for the WorkSpaces deployment (e.g. eu-west-2)"
  type        = string
  default     = "eu-west-2"

}

# -----------------------------------------------------------------------------
# Rule Group 1 — AWS Service Endpoints
# Covers: WorkSpaces Application Manager (WAM), S3, SQS, CloudFront
#
# NOTE: Consider replacing S3 and SQS with VPC Gateway/Interface Endpoints to
# keep that traffic off the internet entirely — you could then remove those
# entries from this list and reduce the attack surface.
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "workspaces_aws_endpoints" {
  name     = "workspaces-aws-endpoints"
  capacity = 17
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
          "wam-idb.${var.aws_region}.amazonaws.com",
          "wam-ps.${var.aws_region}.amazonaws.com",
          ".s3.amazonaws.com", # covers s3.amazonaws.com and *.s3.amazonaws.com
          ".s3-external-1.amazonaws.com",
          ".s3-${var.aws_region}.amazonaws.com",
          "sqs.${var.aws_region}.amazonaws.com",
          "cloudfront.amazonaws.com",
        ]
      }
    }
  }

  tags = {
    Name = "workspaces-aws-endpoints"
  }
}

# -----------------------------------------------------------------------------
# Rule Group 2 — Microsoft Services
# Covers: Windows Update, Windows Defender, Office 365, Azure AD / Identity,
#         SharePoint Online, Teams, OneDrive (via officeapps), Azure platform,
#         CDN delivery networks
#
# Key consolidations vs original list:
#   ".microsoft.com"     — replaces all individual *.microsoft.com entries
#   ".windows.net"       — replaces *.blob.core.windows.net, *.queue.core.windows.net,
#                          *.table.core.windows.net, *.servicebus.windows.net,
#                          login.windows.net, enterpriseregistration.windows.net etc.
#   ".office.com"        — replaces all individual portal/admin/forms/teams subdomains
#   ".office.net"        — replaces *.cdn.office.net, *.osi.office.net entries etc.
#   ".office365.com"     — replaces outlook.office365.com, *.res.office365.com etc.
#   ".officeapps.live.com" — replaces all nexus/odc/broadcast/excel/word etc. subdomains
#   ".microsoftonline.com" — replaces all individual Azure AD endpoint entries
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "workspaces_microsoft_services" {
  name     = "workspaces-microsoft-services"
  capacity = 150
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
          ".windowsupdate.com", # covers *.windowsupdate.com and *.download.windowsupdate.com
          "wustat.windows.com",
          "client.wns.windows.com",
          "skydrive.wns.windows.com",
          "adldefinitionupdates-wu.azurewebsites.net",

          # Microsoft (broad — mirrors original list; covers all *.microsoft.com at any depth)
          ".microsoft.com",
          "c.s-microsoft.com", # root is s-microsoft.com, NOT covered by .microsoft.com

          # Azure / Windows platform
          ".windows.net", # covers all *.windows.net subdomains
          "management.azure.com",
          "amp.azure.net",
          ".adhybridhealth.azure.com",
          ".informationprotection.azure.com",
          "informationprotection.hosting.portal.azure.net",
          ".portal.cloudappsecurity.com",
          ".cloudapp.net",
          ".aadrm.com",
          ".azurerms.com",

          # Azure AD / Identity
          ".microsoftonline.com", # covers all individual Azure AD endpoint subdomains
          ".microsoftonline-p.com",
          ".microsoftonline-p.net",
          "autologon.microsoftazuread-sso.com",
          "policykeyservice.dc.ad.msft.net",
          ".msauth.net",
          ".msauthimages.net",
          ".msftauth.net",
          ".msftauthimages.net",
          ".phonefactor.net",
          ".msappproxy.net",

          # Office 365 (covers portal, admin, forms, SharePoint, Teams, StaffHub etc.)
          ".office.com",
          ".office.net",
          ".office365.com",
          ".officeapps.live.com", # covers all broadcast/excel/word/nexus/odc subdomains
          ".outlook.com",
          ".onenote.com",
          ".sharepointonline.com",
          "teams.microsoft.com",

          # CDN / delivery
          ".msecnd.net",
          ".akamaized.net",
          "spoprod-a.akamaihd.net",
          "ajax.aspnetcdn.com",
          "assets.onestore.ms",
          "auth.gfx.ms",
          "mem.gfx.ms",
          "prod.msocdn.com",
          "shellprod.msocdn.com",
          ".hockeyapp.net",

          # Misc Microsoft-adjacent services
          "dc.services.visualstudio.com",
          "ecn.dev.virtualearth.net",
          "platform.linkedin.com",
          "tokensit.cp.microsoft-tst.com", # Microsoft test tenant CP endpoint
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
  name     = "workspaces-onedrive-live-misc"
  capacity = 150
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
          # OneDrive
          ".onedrive.com",
          ".onedrive.live.com",
          ".storage.live.com",
          ".livefilestore.com",
          ".storage.msn.com",

          # live.com services
          "login.live.com",
          "g.live.com",
          "ssw.live.com",
          "msagfx.live.com",
          "client.hip.live.com",
          "wu.client.hip.live.com",
          "oauth.live.com",
          "favorites.live.com",
          ".office.live.com",   # covers *.groups.office.live.com etc.
          ".photos.live.com",   # covers *.groups.photos.live.com etc.
          ".skydrive.live.com", # covers *.groups.skydrive.live.com etc.

          # live.net
          "api.live.net",
          "apis.live.net",
          ".docs.live.net",
          ".policies.live.net",
          ".settings.live.net",
          "skyapi.live.net",
          "snapi.live.net",

          # OneDrive delivery / SFX
          "oneclient.sfx.ms",
          "p.sfx.ms",
          ".files.1drv.com",

          # MOJ specific
          "sts.justice.gov.uk",
          "justiceuk-my.sharepoint.com",

          # Windows network connectivity test
          "www.msftconnecttest.com",

          # CyberDuck update check
          "version.cyberduck.io",

          # Office first-party add-in delivery
          "firstpartyapps.oaspapps.com",
          "telemetryservice.firstpartyapps.oaspapps.com",
          "prod.firstpartyapps.oaspapps.com.akadns.net",
          "wus-firstpartyapps.oaspapps.com",

          # StaffHub (legacy) # REVIEW — Microsoft retired StaffHub Jan 2020
          "staffhub.ms",
          "staffhub.uservoice.com",
          "staffhubweb.azureedge.net",
          "outlook.uservoice.com",

          # Analytics / engagement SDKs # REVIEW — mobile-oriented, likely not needed for desktop WorkSpaces
          ".helpshift.com",
          ".localytics.com",
          "cdn.optimizely.com",
          ".log.optimizely.com",
          ".o365weve.com",
          ".branch.io",
          ".adjust.com",
          ".crashlytics.com",
          "fabric.io",
          ".mesh.com",
          "vas.samsungapps.com",
          "connect.facebook.net", # REVIEW — used by some Office add-ins
        ]
      }
    }
  }

  tags = {
    Name = "workspaces-onedrive-live-misc"
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
#   ".verisign.com"    — replaces all evintl-*/evsecure-* entries
#   ".usertrust.com"   — replaces crl/ocsp/crt.usertrust.com
#   ".omniroot.com"    — replaces cacert/cacert.a/ocsp/vassg142.* entries
#   ".letsencrypt.org" — replaces cert.int-x3 and ocsp.int-x3 entries
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "workspaces_certificate_authorities" {
  name     = "workspaces-certificate-authorities"
  capacity = 150
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
          ".digicert.com",
          ".globalsign.com",
          ".globalsign.net",
          ".entrust.net",
          ".geotrust.com",
          ".verisign.com",
          ".verisign.net",
          ".symcb.com",
          ".symcd.com",
          ".omniroot.com",
          ".public-trust.com",
          ".identrust.com",
          ".letsencrypt.org",
          ".usertrust.com",
          "ocsp.msocsp.com", # Microsoft OCSP responder — not under .microsoft.com TLD
          "crl.sectigo.com",
          "ocsp.sectigo.com",
        ]
      }
    }
  }

  tags = {
    Name = "workspaces-certificate-authorities"
  }
}

# -----------------------------------------------------------------------------
# WorkSpaces Network Firewall policy and firewall
# -----------------------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "workspaces_web_allowlist" {
  count       = local.environment == "development" ? 1 : 0
  name        = "workspaces-web-allowlist-policy"
  description = "Allow only approved WorkSpaces FQDN traffic and drop all other stateful traffic."

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_default_actions           = ["aws:drop_strict"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.workspaces_aws_endpoints.arn
    }

    stateful_rule_group_reference {
      priority     = 2
      resource_arn = aws_networkfirewall_rule_group.workspaces_microsoft_services.arn
    }

    stateful_rule_group_reference {
      priority     = 3
      resource_arn = aws_networkfirewall_rule_group.workspaces_onedrive_live_misc.arn
    }

    stateful_rule_group_reference {
      priority     = 4
      resource_arn = aws_networkfirewall_rule_group.workspaces_certificate_authorities.arn
    }
  }

  tags = {
    Name = "workspaces-web-allowlist-policy"
  }
}

resource "aws_networkfirewall_firewall" "workspaces_web_allowlist" {
  count               = local.environment == "development" ? 1 : 0
  name                = "workspaces-web-allowlist-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.workspaces_web_allowlist[0].arn
  vpc_id              = aws_vpc.workspaces[0].id

  subnet_mapping {
    subnet_id = aws_subnet.firewall_a[0].id
  }

  subnet_mapping {
    subnet_id = aws_subnet.firewall_b[0].id
  }

  tags = {
    Name = "workspaces-web-allowlist-firewall"
  }
}

# CloudWatch Log Groups for firewall
resource "aws_cloudwatch_log_group" "firewall_flow_logs" {
  count             = local.environment == "development" ? 1 : 0
  name              = "/aws/network-firewall/workspaces/flow-logs"
  retention_in_days = 7

  tags = {
    Name = "workspaces-firewall-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "firewall_alert_logs" {
  count             = local.environment == "development" ? 1 : 0
  name              = "/aws/network-firewall/workspaces/alert-logs"
  retention_in_days = 7

  tags = {
    Name = "workspaces-firewall-alert-logs"
  }
}

# Enable firewall logging
resource "aws_networkfirewall_logging_configuration" "workspaces" {
  count           = local.environment == "development" ? 1 : 0
  firewall_arn    = aws_networkfirewall_firewall.workspaces_web_allowlist[0].arn
  logging_configuration {
    log_destination_config {
      log_destination       = aws_cloudwatch_log_group.firewall_alert_logs[0].arn
      log_destination_type  = "CLOUDWATCH_LOGS"
      log_type              = "ALERT"
    }
  }
}
