#!/bin/bash
bucket=int-nomis-lb-access-logs20230105131538061200000001
aws s3api list-object-versions --bucket $bucket | jq -r '.Versions[] | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | xargs -L 1 aws s3api delete-object --bucket $bucket
