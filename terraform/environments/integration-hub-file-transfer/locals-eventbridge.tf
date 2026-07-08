locals {
  eventbridge_incoming_s3_rules = {
    incoming_object_created = {
      name        = "${local.application_name}-incoming-object-created"
      description = "Route incoming bucket object created events to the incoming processing queue"
      event_pattern = {
        source        = ["aws.s3"]
        "detail-type" = ["Object Created"]
        detail = {
          bucket = {
            name = [module.s3_bucket["incoming"].s3_bucket_id]
          }
          object = {
            size = [
              {
                numeric = ["<=", 5000000000]
              }
            ]
          }
        }
      }
    }
  }

  eventbridge_guard_duty_malware_protection_for_s3_rules = {
    no_threats_found = {
      name                   = "${local.application_name}-guardduty-no-threats-found"
      description            = "Route clean objects after a successful GuardDuty Malware Protection for S3 scan"
      destination_bucket_key = "clean"
      delete_source          = true
      event_pattern = {
        source        = ["aws.guardduty"]
        "detail-type" = ["GuardDuty Malware Protection Object Scan Result"]
        resources     = [aws_guardduty_malware_protection_plan.this.arn]
        detail = {
          resourceType = ["S3_OBJECT"]
          s3ObjectDetails = {
            bucketName = [module.s3_bucket["processing"].s3_bucket_id]
          }
          scanResultDetails = {
            scanResultStatus = ["NO_THREATS_FOUND"]
          }
        }
      }
    }

    threats_found = {
      name                   = "${local.application_name}-guardduty-threats-found"
      description            = "Route quarantined objects after a GuardDuty Malware Protection for S3 detection"
      destination_bucket_key = "quarantine"
      delete_source          = true
      event_pattern = {
        source        = ["aws.guardduty"]
        "detail-type" = ["GuardDuty Malware Protection Object Scan Result"]
        resources     = [aws_guardduty_malware_protection_plan.this.arn]
        detail = {
          resourceType = ["S3_OBJECT"]
          s3ObjectDetails = {
            bucketName = [module.s3_bucket["processing"].s3_bucket_id]
          }
          scanResultDetails = {
            scanResultStatus = ["THREATS_FOUND"]
          }
        }
      }
    }

    investigation = {
      name                   = "${local.application_name}-guardduty-investigation"
      description            = "Route objects for investigation when a GuardDuty Malware Protection for S3 scan is skipped or fails"
      destination_bucket_key = "investigation"
      delete_source          = true
      event_pattern = {
        source        = ["aws.guardduty"]
        "detail-type" = ["GuardDuty Malware Protection Object Scan Result"]
        resources     = [aws_guardduty_malware_protection_plan.this.arn]
        detail = {
          resourceType = ["S3_OBJECT"]
          s3ObjectDetails = {
            bucketName = [module.s3_bucket["processing"].s3_bucket_id]
          }
          scanResultDetails = {
            scanResultStatus = ["UNSUPPORTED", "ACCESS_DENIED", "FAILED"]
          }
        }
      }
    }
  }
} 