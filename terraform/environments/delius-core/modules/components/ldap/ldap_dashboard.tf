resource "aws_cloudwatch_dashboard" "ldap_dashboard" {
  dashboard_name = "LDAPDashboard"

  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'BIND dn="cn=*,ou=Users,dc=moj,dc=com"' as user_cn
            | filter @message like /BIND dn="cn=/ and @message like /ou=Users,dc=moj,dc=com/ and @message like /method=128/
            | stats count() as number_of_logins by bin(5m)
          EOT
          "logGroupNames" = [
            "${var.env_name}/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Total num of LDAP Logins"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'BIND dn="cn=*,ou=Users,dc=moj,dc=com"' as user_cn
            | filter @message like /BIND dn="cn=/ and @message like /ou=Users,dc=moj,dc=com/ and @message like /method=128/
            | stats count_distinct(user_cn) as unique_users by bin(5m)
          EOT
          "logGroupNames" = [
            "prod/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Unique User Logins in past 1 hour"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'conn=* op=* RESULT tag=* err=* qtime=* etime=* text=*' as conn_id, op_id, tag, err, qtime, etime, text
            | filter tag=97  # BIND operation result
            | stats avg(etime) as avg_response_time, max(etime) as max_response_time by bin(5m)
          EOT
          "logGroupNames" = [
            "prod/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Average & Max Elapsed / Response time"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'conn=* op=* RESULT tag=* err=* qtime=* etime=* text=*' as conn_id, op_id, tag, err, qtime, etime, text
            | filter tag=97  # BIND operation result
            | stats avg(qtime) as avg_queue_time by bin(5m)
          EOT
          "logGroupNames" = [
            "prod/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Average Query Time"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'conn=* op=* SEARCH RESULT tag=* err=* qtime=* etime=* nentries=* text=*' as conn_id, op_id, tag, err, qtime, etime, nentries, text
            | filter tag=101  # SEARCH RESULT operation
            | stats avg(etime) as avg_search_response_time, max(etime) as max_search_resp_time by bin(5m)
          EOT
          "logGroupNames" = [
            "prod/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Average & Max Response Times for Searches"
        }
      },
      {
        "type"   = "log",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "query" = <<-EOT
            fields @timestamp, @message
            | parse @message 'conn=* op=* SEARCH RESULT tag=* err=* qtime=* etime=* nentries=* text=*' as conn_id, op_id, tag, err, qtime, etime, nentries, text
            | filter tag=101  # SEARCH RESULT operation
            | stats avg(qtime) as avg_queue_time by bin(5m)
          EOT
          "logGroupNames" = [
            "prod/ldap"
          ],
          "region" = "eu-west-2",
          "title"  = "Average Query Times for Searches"
        }
      }
    ]
  })
}
