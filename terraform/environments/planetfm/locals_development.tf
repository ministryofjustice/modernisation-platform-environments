# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_s3_buckets = {
      public-lb-logs-bucket = {
        bucket_policy_v2 = [
          {
            effect = "Allow"
            actions = [
              "s3:PutObject",
            ]
            principals = {
              identifiers = ["arn:aws:iam::652711504416:root"]
              type        = "AWS"
            }
          },
          {
            effect = "Allow"
            actions = [
              "s3:PutObject"
            ]
            principals = {
              identifiers = ["delivery.logs.amazonaws.com"]
              type        = "Service"
            }

            conditions = [
              {
                test     = "StringEquals"
                variable = "s3:x-amz-acl"
                values   = ["bucket-owner-full-control"]
              }
            ]
          },
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketAcl"
            ]
            principals = {
              identifiers = ["delivery.logs.amazonaws.com"]
              type        = "Service"
            }
          }
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_lbs = {

      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        loadbalancer_type                = "application"
        idle_timeout                     = 3600
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true
        access_logs                      = true #default value
        force_destroy_bucket             = true
        # not required for testing in sandbox
        instance_target_groups = {}
        # not required for testing in sandbox
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type             = "fixed-response"
              fixed_response   = {
                content_type = "text/plain"
                message_body = "Private LB Reply"
                status_code  = "503"
              }
            }
          }
        }
      }
      public = {
        internal_lb                      = true
        enable_delete_protection         = false
        loadbalancer_type                = "application"
        idle_timeout                     = 3600
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true
        access_logs                      = true #default value is true
        force_destroy_bucket             = true
        existing_bucket_name             = "public-lb-logs-bucket20231218121709816700000001"
        # not required for testing in sandbox
        instance_target_groups = {}
        # not required for testing in sandbox
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type             = "fixed-response"
              fixed_response   = {
                content_type = "text/plain"
                message_body = "Public LB Reply"
                status_code  = "503"
              }
            }
          }
        }
      }
    }
  }
}

