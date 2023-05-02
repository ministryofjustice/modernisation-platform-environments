#!/bin/bash
aws s3api list-object-versions --bucket int-nomis-lb-access-logs20230105131538061200000001 | jq -r '.Versions[] | "aws s3api delete-object --bucket int-nomis-lb-access-logs20230105131538061200000001 --key \"\(.Key)\" --version-id \"\(.VersionId)\""'
