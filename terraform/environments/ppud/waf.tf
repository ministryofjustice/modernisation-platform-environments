
resource "aws_wafv2_web_acl" "WAM-rule" {
  name  = "WAM-rule"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
     managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }


  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesWindowsRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWindowsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesWindowsRuleSet"
      sampled_requests_enabled   = true
    }
  }

    rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }
/*
  rule {
    name  = "regex-rule"
    priority = 6

    statement {
      regex_pattern_set_reference_statement {
        arn = "arn:aws:wafv2:eu-west-2:359821628648:regional/regexpatternset/sqlinjection/59624cfe-d40e-4c1e-88e2-8550b0401bc8"
          field_to_match {
              body {
                  oversize_handling = "CONTINUE"
            }
          }
           text_transformation {
               priority = 0
               type = "None"
            }
        }
      }
       action  {
        block {}
      }
       visibility_config {
         sampled_requests_enabled = true
         cloudwatch_metrics_enabled = true
         metric_name = "regexrule"
      }
    }
*/
    rule {
    name     = "RateLimitingRule"
    priority = 7

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 5000
        aggregate_key_type = "IP"

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitingRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "query-string-rule"
    priority = 8
    action {
      block { }
    }

    statement {
      byte_match_statement {
        positional_constraint = "CONTAINS"
        search_string = "admin"
        field_to_match {
         uri_path { }
        }
        
        text_transformation {
          priority = 0
          type     = "NONE"
        }
    }
  }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "string-rule"
      sampled_requests_enabled   = true
}
  }
 

  rule {
    name     = "geolocation"
    priority = 9

    statement {
     geo_match_statement {
      country_codes = ["GB"]  
    }
  }
/*
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["GB"]
      }
    }
  }
}
*/
    action {
      allow {}
    }
     
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Geolocation"
      sampled_requests_enabled   = true
    }
  }


/*
  tags = {
    Name = "${var.prefix}-${var.name}"
  }
*/

 visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "PPUDRules"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_web_acl_association" "ALB1-WAF" {
  resource_arn = aws_lb.PPUD-ALB.arn
  web_acl_arn = aws_wafv2_web_acl.WAM-rule.arn
}

resource "aws_wafv2_web_acl_association" "ALB2-WAF" {
  resource_arn = aws_lb.WAM-ALB.arn
  web_acl_arn = aws_wafv2_web_acl.WAM-rule.arn
}