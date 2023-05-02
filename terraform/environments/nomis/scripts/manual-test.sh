#!/bin/bash
## terraform import 'module.baseline.module.s3_bucket["int-nomis-lb-access-logs"].aws_s3_bucket.default' 'int-nomis-lb-access-logs20230105131538061200000001'
#terraform import arn:aws:s3:::int-nomis-lb-access-logs20230105134719554800000001
bucket=int-nomis-lb-access-logs20230105131538061200000001
aws s3api list-object-versions --bucket $bucket | jq -r '.Versions[] | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | xargs -L 1 aws s3api delete-object --bucket $bucket
