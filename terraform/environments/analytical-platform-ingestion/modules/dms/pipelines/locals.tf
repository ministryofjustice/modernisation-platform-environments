locals {

  protected_dbs = [
    {
      name                    = "tariff"
      database_string_pattern = ["tariff*"]
      role_names_to_exempt = [
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    },
    {
      name                    = "tempus"
      database_string_pattern = ["tempus*"]
      role_names_to_exempt = [
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    }
  ]

  unique_role_names = distinct(flatten([for db in local.protected_dbs : db.role_names_to_exempt])) // to retrieve unique_ids

  data_engineering_buckets = {
    "alpha-data-engineer-logs" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "alpha-data-engineer-logs/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Effect    = "Deny"
              Principal = "*"
              Resource  = "arn:aws:s3:::alpha-data-engineer-logs"
              Sid       = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-athena-query-dump" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = false,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-athena-query-dump/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        abort_incomplete_multipart_upload_days = 7,
        enabled                                = true
        id                                     = "keep_3_days"
        expiration = {
          days = 3
        }
        },
        {
          abort_incomplete_multipart_upload_days = 1,
          enabled                                = true
          id                                     = "properly delete non current objects"

          expiration = {
            days                         = 0
            expired_object_delete_marker = true
          }

          noncurrent_version_expiration = {
            days = 1
          }
        }
      ]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-athena-query-dump/*",
                "arn:aws:s3:::mojap-athena-query-dump"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-land/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tariff/*"
              Sid      = "WriteDeleteAccess-mojap-land-cica-tariff"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "ListBucketObjects-mojap-land-tariff"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tariff/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-cica-tariff"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tariff/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-cica-tariff"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tempus/*"
              Sid      = "WriteDeleteAccess-mojap-land-cica-tempus"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "ListBucketObjects-mojap-land-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tempus/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-cica-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/cica/tempus/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-cica-tempus"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land/*",
                "arn:aws:s3:::mojap-land"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-land-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-land-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tariff/*"
              Sid      = "WriteDeleteAccess-mojap-land-dev-cica-tariff"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "ListBucketObjects-mojap-land-dev"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tariff/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-dev-cica-tariff"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tariff/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-dev-cica-tariff"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tempus/*"
              Sid      = "WriteDeleteAccess-mojap-land-dev-cica-tempus"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "ListBucketObjects-mojap-land-dev-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tempus/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-dev-cica-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/cica/tempus/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-dev-cica-tempus"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-dev/*",
                "arn:aws:s3:::mojap-land-dev"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-land-fail-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-land-fail-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-fail-dev/*",
                "arn:aws:s3:::mojap-land-fail-dev"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land-fail-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-land-fail-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-fail-preprod/*",
                "arn:aws:s3:::mojap-land-fail-preprod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-land-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tariff/*"
              Sid      = "WriteDeleteAccess-mojap-land-preprod-cica-tariff"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "ListBucketObjects-mojap-land-preprod-tariff"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tariff/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-preprod-cica-tariff"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tariff-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tariff/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-preprod-cica-tariff"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tempus/*"
              Sid      = "WriteDeleteAccess-mojap-land-preprod-cica-tempus"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "ListBucketObjects-mojap-land-preprod-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tempus/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-preprod-cica-tempus"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/tempus-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/cica/tempus/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-preprod-cica-tempus"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-preprod/*",
                "arn:aws:s3:::mojap-land-preprod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-metadata-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-dev/*",
                "arn:aws:s3:::mojap-metadata-dev"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-metadata-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-preprod/*",
                "arn:aws:s3:::mojap-metadata-preprod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-prod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-metadata-prod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-prod/*",
                "arn:aws:s3:::mojap-metadata-prod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-raw-hist" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-raw-hist/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-raw-hist/*",
                "arn:aws:s3:::mojap-raw-hist"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-raw-hist-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-raw-hist-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }

    "mojap-raw-hist-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
      }
      mfa_delete = false
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = false

          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
      logging = {
        target_bucket = "moj-analytics-s3-logs"
        target_prefix = "mojap-raw-hist-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-raw-hist-preprod/*",
                "arn:aws:s3:::mojap-raw-hist-preprod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
  }
}