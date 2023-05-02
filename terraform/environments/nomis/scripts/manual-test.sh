#!/bin/bash
terraform import 'module.baseline.module.s3_bucket["int-nomis-lb-access-logs"].aws_s3_bucket.default' 'int-nomis-lb-access-logs20230105134719554800000001'
