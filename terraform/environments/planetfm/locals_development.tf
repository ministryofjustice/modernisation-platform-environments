# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_s3_buckets = {
      public-lb-logs-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
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
            # resources = "arn:aws:s3:::public-lb-logs-bucket20231215103827601100000001/public/AWSLogs/326533041175/*"
          },
          {
            # sid    = "AWSLogDeliveryWrite"
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
            # resources = "arn:aws:s3:::public-lb-logs-bucket20231215103827601100000001/public/AWSLogs/326533041175/*"
          },
          {
            # sid    = "AWSLogDeliveryAclCheck"
            effect = "Allow"
            actions = [
              "s3:GetBucketAcl"
            ]
            principals = {
              identifiers = ["delivery.logs.amazonaws.com"]
              type        = "Service"
            }
            # resources = "arn:aws:s3:::public-lb-logs-bucket20231215103827601100000001"
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
        log_schedule                     = "cron(0 * * * ? *)"
        force_destroy_bucket             = true
        # not required for testing in sandbox
        instance_target_groups = {}
        # not required for testing in sandbox
        listeners = {}
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
        log_schedule                     = "cron(0 * * * ? *)"
        force_destroy_bucket             = true
        existing_bucket_name             = "public-lb-logs-bucket20231215103827601100000001"
        # not required for testing in sandbox
        instance_target_groups = {}
        # not required for testing in sandbox
        listeners = {}
      }
    }
  }
}

