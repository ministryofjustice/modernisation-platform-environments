resource "aws_cloudwatch_dashboard" "ldap_dashboard" {
  dashboard_name = "${var.env_name}-LDAPDashboard"

  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'BIND dn=\"cn=*,ou=Users,dc=moj,dc=com\"' as user_cn\n| filter @message like /BIND dn=\"cn=/ and @message like /ou=Users,dc=moj,dc=com/ and @message like /method=128/\n| stats count() as number_of_logins by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Total num of LDAP Logins"
        }
      },
      {
        "type"   = "log",
        "x"      = 12,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'BIND dn=\"cn=*,ou=Users,dc=moj,dc=com\"' as user_cn\n| filter @message like /BIND dn=\"cn=/ and @message like /ou=Users,dc=moj,dc=com/ and @message like /method=128/\n| stats count_distinct(user_cn) as unique_users by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Unique User Logins in past 1 hour"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* RESULT tag=* err=* qtime=* etime=* text=*' as conn_id, op_id, tag, err, qtime, etime, text\n| filter tag=97\n| stats avg(etime) as avg_response_time, max(etime) as max_response_time by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Average & Max Elapsed / Response time"
        }
      },
      {
        "type"   = "log",
        "x"      = 12,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* RESULT tag=* err=* qtime=* etime=* text=*' as conn_id, op_id, tag, err, qtime, etime, text\n| filter tag=97\n| stats avg(qtime) as avg_queue_time by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Average Query Time"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 12,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* SEARCH RESULT tag=* err=* qtime=* etime=* nentries=* text=*' as conn_id, op_id, tag, err, qtime, etime, nentries, text\n| filter tag=101\n| stats avg(etime) as avg_search_response_time, max(etime) as max_search_resp_time by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Average & Max Response Times for Searches"
        }
      },
      {
        "type"   = "log",
        "x"      = 12,
        "y"      = 12,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* SEARCH RESULT tag=* err=* qtime=* etime=* nentries=* text=*' as conn_id, op_id, tag, err, qtime, etime, nentries, text\n| filter tag=101\n| stats avg(qtime) as avg_queue_time by bin(5m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Average Query Times for Searches"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 18,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* SRCH base=* scope=* deref=* filter=\"*\"' as conn_id, op_id, base, scope, deref, filter\n| filter @message like /SRCH base=/\n| stats count(*) as total_searches, count_distinct(filter) as unique_searches",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Total number of Searches / unique ones"
        }
      },
      {
        "type"   = "log",
        "x"      = 12,
        "y"      = 18,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query"   = "SOURCE '${var.env_name}-ldap' | fields @timestamp, @message\n| parse @message 'conn=* op=* SRCH base=* scope=* deref=* filter=\"*\"' as conn_id, op_id, base, scope, deref, filter\n| filter @message like /SRCH base=/\n| stats count(*) as total_searches, count_distinct(filter) as unique_searches by bin(30m)",
          "region"  = "eu-west-2",
          "stacked" = false,
          "view"    = "timeSeries",
          "title"   = "Search Counts By Time (half hourly)"
        }
      }
    ]
  })
}
