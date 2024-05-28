locals {
  system = {
    passwordsalt = var.nextcloud_passwordsalt
    secret = var.nextcloud_secret
    trusted_domains = ["${var.app_name}.${var.external_domain}"]
    trusted_proxies = [var.cidr_block_a, var.cidr_block_b, var.cidr_block_c]
    forwarded_for_headers = ["HTTP_X_FORWARDED_FOR"]
    datadirectory = "/var/${var.app_name}/data"
    dbtype = "mysql"
    version = "20.0.0.9"
    overwrite_cli_url = "https://${var.app_name}.${var.external_domain}"
    dbname = var.app_name
    dbhost = "${var.app_name}-db.${var.internal_domain}"
    dbport = ""
    dbtableprefix = "oc_"
    mysql_utf8mb4 = true
    dbuser = var.nextcloud_dbuser
    dbpassword = var.nextcloud_dbpassword
    installed = true
    instanceid = var.nextcloud_id
    lost_password_link = var.env_type == "pre-prod" ? "https://${var.pwm_url}/public/forgottenpassword" : "https://${var.strategic_pwm_url}/public/forgottenpassword"
    session_lifetime = "43200"
    session_keepalive = false
    ldapIgnoreNamingRules = false
    ldapProviderFactory = "OCA\\User_LDAP\\LDAPProviderFactory"
    overwritehost = "${var.app_name}.${var.external_domain}"
    forcessl = true
    log_type = "file"
    logfile = "/var/log/nextcloud/nextcloud.log"
    loglevel = 1
    trashbin_retention_obligation = "30, 32"
    overwriteprotocol = "https"
    memcache_distributed = "\\OC\\Memcache\\Redis"
    memcache_locking = "\\OC\\Memcache\\Redis"
    filelocking_enabled = "true"
    redis = {
      host = var.redis_host
      port = var.redis_port
      timeout = "1.5"
    }
    csrf_disabled = "false"
    filesystem_check_changes = "1"
    mail_smtpmode = "smtp"
    mail_smtphost = var.mail_server
    mail_sendmailmode = "smtp"
    mail_smtpport = "25"
    mail_from_address = var.from_address
    mail_domain = var.external_domain
    auth_webauthn_enabled = false
    maintenance = false
  }
    apps = {
    accessibility = {
      enabled = "yes"
      installed_version = "1.6.0"
      types = ""
    }
    activity = {
      enabled = "yes"
      installed_version = "2.13.1"
      types = "filesystem"
    }
    cloud_federation_api = {
      enabled = "yes"
      installed_version = "1.3.0"
      types = "filesystem"
    }
    comments = {
      enabled = "yes"
      installed_version = "1.10.0"
      types = "logging"
    }
    contactsinteraction = {
      enabled = "yes"
      installed_version = "1.1.0"
      types = "dav"
    }
    core = {
      enterpriseLogoChecked = "yes"
      installedat = "1570694511.5532"
      lastcron = "1603042772"
      lastupdatedat = "0"
      oc_integritycheck_checker = "[]"
      public_files = "files_sharing/public.php"
      public_webdav = "dav/appinfo/v1/publicwebdav.php"
      scss_variables = "c56f3e52ca21a32ed9fd299f482ae5be"
      shareapi_allow_public_upload = "no"
      shareapi_default_permission_cancreate = "yes"
      shareapi_default_permissions = "31"
      vendor = "nextcloud"
    }
    dashboard = {
      enabled = "no"
      installed_version = "7.0.0"
      types = ""
    }
    dav = {
      buildCalendarReminderIndex = "yes"
      buildCalendarSearchIndex = "yes"
      enabled = "yes"
      installed_version = "1.16.0"
      regeneratedBirthdayCalendarsForYearFix = "yes"
      types = "filesystem"
    }
    federatedfilesharing = {
      enabled = "yes"
      installed_version = "1.10.1"
      types = ""
    }
    federation = {
      enabled = "yes"
      installed_version = "1.10.1"
      types = "authentication"
    }
    files = {
      cronjob_scan_files = "500"
      default_quota = "5 GB"
      enabled = "yes"
      installed_version = "1.15.0"
      types = "filesystem"
    }
    files_pdfviewer = {
      enabled = "yes"
      installed_version = "2.0.1"
      types = ""
    }
    files_rightclick = {
      enabled = "yes"
      installed_version = "0.17.0"
      types = ""
    }
    files_sharing = {
      enabled = "yes"
      installed_version = "1.12.0"
      types = "filesystem"
    }
    files_texteditor = {
      enabled = "yes"
      installed_version = "2.8.0"
      types = ""
    }
    files_trashbin = {
      enabled = "yes"
      installed_version = "1.10.1"
      types = "filesystem,dav"
    }
    files_versions = {
      enabled = "yes"
      installed_version = "1.13.0"
      types = "filesystem,dav"
    }
    files_videoplayer = {
      enabled = "yes"
      installed_version = "1.9.0"
      types = ""
    }
    firstrunwizard = {
      enabled = "yes"
      installed_version = "2.9.0"
      types = "logging"
    }
    gallery = {
      enabled = "yes"
      installed_version = "18.4.0"
      types = ""
    }
    logreader = {
      enabled = "yes"
      installed_version = "2.5.0"
      types = ""
    }
    lookup_server_connector = {
      enabled = "yes"
      installed_version = "1.8.0"
      types = "authentication"
    }
    nextcloud_announcements = {
      enabled = "yes"
      installed_version = "1.9.0"
      pub_date = "Thu, 24 Oct 2019 00:00:00 +0200"
      types = "logging"
    }
    notifications = {
      enabled = "yes"
      installed_version = "2.8.0"
      types = "logging"
    }
    oauth2 = {
      enabled = "yes"
      installed_version = "1.8.0"
      types = "authentication"
    }
    password_policy = {
      enabled = "yes"
      installed_version = "1.10.1"
      types = "authentication"
    }
    photos = {
      enabled = "yes"
      installed_version = "1.2.0"
      types = ""
    }
    privacy = {
      enabled = "yes"
      fullDiskEncryptionEnabled = "1"
      installed_version = "1.4.0"
      readableLocation = "gb"
      types = ""
    }
    provisioning_api = {
      enabled = "yes"
      installed_version = "1.10.0"
      types = "prevent_group_restriction"
    }
    recommendations = {
      enabled = "yes"
      installed_version = "0.8.0"
      types = ""
    }
    serverinfo = {
      enabled = "yes"
      installed_version = "1.10.0"
      types = ""
    }
    settings = {
      enabled = "yes"
      installed_version = "1.2.0"
      types = ""
    }
    sharebymail = {
      enabled = "yes"
      enforcePasswordProtection = "yes"
      installed_version = "1.10.0"
      types = "filesystem"
    }
    support = {
      SwitchUpdaterServerHasRun = "yes"
      enabled = "yes"
      installed_version = "1.3.0"
      types = "session"
    }
    survey_client = {
      enabled = "yes"
      installed_version = "1.8.0"
      types = ""
    }
    systemtags = {
      enabled = "yes"
      installed_version = "1.10.0"
      types = "logging"
    }
    text = {
      enabled = "yes"
      installed_version = "3.1.0"
      types = "dav"
    }
    theming = {
      backgroundMime = "backgroundColor"
      cachebuster = "2"
      enabled = "yes"
      installed_version = "1.11.0"
      types = "logging"
    }
    twofactor_backupcodes = {
      enabled = "yes"
      installed_version = "1.9.0"
      types = ""
    }
    twofactor_totp = {
      enabled = "yes"
      installed_version = "5.0.0"
      types = ""
    }
    updatenotification = {
      core = "18.0.10.2"
      enabled = "yes"
      files_rightclick = "0.15.1"
      files_texteditor = "2.11.0"
      installed_version = "1.10.0"
      types = ""
      update_check_errors = "0"
    }
        user_status = {
      enabled = "yes"
      installed_version = "1.0.0"
      types = ""
    }
    viewer = {
      enabled = "yes"
      installed_version = "1.4.0"
      types = ""
    }
    weather_status = {
      enabled = "yes"
      installed_version = "1.0.0"
      types = ""
    }
    workflowengine = {
      enabled = "yes"
      installed_version = "2.2.0"
      types = "filesystem"
    }
  }
}


