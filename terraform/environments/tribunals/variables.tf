variable "lookup_cloudfront_distribution" {
  type        = bool
  description = "Set to true after the CloudFront distribution has been created and stored in SSM"
  default     = false
}

variable "services" {
  type = map(object({
    name_prefix = string
    module_key  = string
    port        = number
  }))
  default = {
    "appeals" = {
      name_prefix = "administrativeappeals"
      module_key  = "administrativeappeals"
      port        = 49100
    },
    "ahmlr" = {
      name_prefix = "landregistrationdivision"
      module_key  = "landregistrationdivision"
      port        = 49101
    }
    "care_standards" = {
      name_prefix = "carestandards"
      module_key  = "carestandards"
      port        = 49102
    },
    "cicap" = {
      name_prefix = "cicap"
      module_key  = "cicap"
      port        = 49103
    },
    "employment_appeals" = {
      name_prefix = "employmentappeals"
      module_key  = "employmentappeals"
      port        = 49104
    },
    "finance_and_tax" = {
      name_prefix = "financeandtax"
      module_key  = "financeandtax"
      port        = 49105
    },
    "immigration_services" = {
      name_prefix = "immigrationservices"
      module_key  = "immigrationservices"
      port        = 49106
    },
    "information_tribunal" = {
      name_prefix = "informationrights"
      module_key  = "informationrights"
      port        = 49107
    },
    "lands_tribunal" = {
      name_prefix = "landschamber"
      module_key  = "landschamber"
      port        = 49108
    },
    "transport" = {
      name_prefix = "transportappeals"
      module_key  = "transportappeals"
      port        = 49109
    },
    "asylum_support" = {
      name_prefix = "asylumsupport"
      module_key  = "asylumsupport"
      port        = 49120
    },
    "charity_tribunal_decisions" = {
      name_prefix = "charity"
      module_key  = "charity"
      port        = 49110
    },
    "claims_management_decisions" = {
      name_prefix = "claimsmanagement"
      module_key  = "claimsmanagement"
      port        = 49111
    },
    "consumer_credit_appeals" = {
      name_prefix = "consumercreditappeals"
      module_key  = "consumercreditappeals"
      port        = 49112
    },
    "estate_agent_appeals" = {
      name_prefix = "estateagentappeals"
      module_key  = "estateagentappeals"
      port        = 49113
    },
    "primary_health_lists" = {
      name_prefix = "phl"
      module_key  = "phl"
      port        = 49114
    },
    "siac" = {
      name_prefix = "siac"
      module_key  = "siac"
      port        = 49115
    },
    "tax_chancery_decisions" = {
      name_prefix = "taxandchancery_ut"
      module_key  = "taxchancerydecisions"
      port        = 49117
    },
    "tax_tribunal_decisions" = {
      name_prefix = "tax"
      module_key  = "tax"
      port        = 49118
    },
    "ftp_admin_appeals" = {
      name_prefix = "adminappeals"
      module_key  = "adminappeals"
      port        = 49119
    }
  }
}

variable "web_app_services" {
  type = map(object({
    name_prefix = string
    module_key  = string
    port        = number
    app_db_name = string
  }))
  default = {
    "appeals" = {
      name_prefix = "administrativeappeals"
      module_key  = "appeals"
      port        = 49100
      app_db_name = "ossc"
    },
    "ahmlr" = {
      name_prefix = "landregistrationdivision"
      module_key  = "ahmlr"
      port        = 49101
      app_db_name = "hmlands"
    }
    "care_standards" = {
      name_prefix = "carestandards"
      module_key  = "care_standards"
      port        = 49102
      app_db_name = "carestandards"
    },
    "cicap" = {
      name_prefix = "cicap"
      module_key  = "cicap"
      port        = 49103
      app_db_name = "cicap"
    },
    "employment_appeals" = {
      name_prefix = "employmentappeals"
      module_key  = "employment_appeals"
      port        = 49104
      app_db_name = "eat"
    },
    "finance_and_tax" = {
      name_prefix = "financeandtax"
      module_key  = "finance_and_tax"
      port        = 49105
      app_db_name = "ftt"
    },
    "immigration_services" = {
      name_prefix = "immigrationservices"
      module_key  = "immigration_services"
      port        = 49106
      app_db_name = "imset"
    },
    "information_tribunal" = {
      name_prefix = "informationrights"
      module_key  = "information_tribunal"
      port        = 49107
      app_db_name = "it"
    },
    "lands_tribunal" = {
      name_prefix = "landschamber"
      module_key  = "lands_tribunal"
      port        = 49108
      app_db_name = "lands"
    },
    "transport" = {
      name_prefix = "transportappeals"
      module_key  = "transport"
      port        = 49109
      app_db_name = "transport"
    },
    "asylum_support" = {
      name_prefix = "asylumsupport"
      module_key  = "asylum_support"
      port        = 49120
      app_db_name = "asadj"
    }
  }
}

variable "sftp_services" {
  type = map(object({
    name_prefix    = string
    module_key     = string
    sftp_port      = number
    upload_enabled = bool
  }))
  default = {
    "charity_tribunal_decisions" = {
      name_prefix    = "charitytribunal"
      module_key     = "charity_tribunal_decisions"
      sftp_port      = 10022
      upload_enabled = true
    },
    "claims_management_decisions" = {
      name_prefix    = "claimsmanagement"
      module_key     = "claims_management_decisions"
      sftp_port      = 10023
      upload_enabled = true
    },
    "consumer_credit_appeals" = {
      name_prefix    = "consumercreditappeals"
      module_key     = "consumer_credit_appeals"
      sftp_port      = 10024
      upload_enabled = true
    },
    "estate_agent_appeals" = {
      name_prefix    = "estateagentappeals"
      module_key     = "estate_agent_appeals"
      sftp_port      = 10025
      upload_enabled = true
    },
    "primary_health_lists" = {
      name_prefix    = "primaryhealthlists"
      module_key     = "primary_health_lists"
      sftp_port      = 10026
      upload_enabled = false
    },
    "siac" = {
      name_prefix    = "siac"
      module_key     = "siac"
      sftp_port      = 10027
      upload_enabled = true
    },
    "tax_chancery_decisions" = {
      name_prefix    = "taxchancerydecisions"
      module_key     = "tax_chancery_decisions"
      sftp_port      = 10029
      upload_enabled = true
    },
    "tax_tribunal_decisions" = {
      name_prefix    = "taxtribunaldecisions"
      module_key     = "tax_tribunal_decisions"
      sftp_port      = 10030
      upload_enabled = true
    },
    "ftp_admin_appeals" = {
      name_prefix    = "adminappealsreports"
      module_key     = "ftp_admin_appeals"
      sftp_port      = 10031
      upload_enabled = true
    }
  }
}